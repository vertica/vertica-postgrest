{-# LANGUAGE QuasiQuotes #-}

module PostgREST.Config.Database
  ( pgVersionStatement
  , queryDbSettings
  , queryPgVersion
  ) where

import PostgREST.Config.PgVersion (PgVersion (..))

import qualified Hasql.Decoders             as HD
import qualified Hasql.Encoders             as HE
import           Hasql.Session              (Session, statement)
import qualified Hasql.Statement            as SQL
import qualified Hasql.Transaction          as SQL
import qualified Hasql.Transaction.Sessions as SQL

import Text.InterpolatedString.Perl6 (q)

import Protolude

queryPgVersion :: Session PgVersion
queryPgVersion = statement mempty pgVersionStatement

pgVersionStatement :: SQL.Statement () PgVersion
pgVersionStatement = SQL.Statement sql HE.noParams versionRow False
  where
    sql = "SELECT 0, VERSION()"
    versionRow = HD.singleRow $ PgVersion <$> column HD.int4 <*> column HD.text

queryDbSettings :: Bool -> Session [(Text, Text)]
queryDbSettings prepared =
  let transaction = if prepared then SQL.transaction else SQL.unpreparedTransaction in
  transaction SQL.ReadCommitted SQL.Read $ SQL.statement mempty dbSettingsStatement

-- | Get db settings from the connection role. Global settings will be overridden by database specific settings.
dbSettingsStatement :: SQL.Statement () [(Text, Text)]
dbSettingsStatement = SQL.Statement sql HE.noParams decodeSettings False
  where
    sql = [q|
      WITH
      role_setting (database, setting) AS (
        SELECT setdatabase,
               unnest(setconfig)
          FROM public.pg_db_role_setting
         WHERE setrole = 0
           AND setdatabase IN (0, (SELECT oid FROM public.pg_database WHERE datname = 'vertica'))
      ),
      kv_settings (database, k, v) AS (
        SELECT database,
               substr(setting, 1, strpos(setting, '=') - 1),
               substr(setting, strpos(setting, '=') + 1)
          FROM role_setting
         WHERE setting LIKE 'pgrst.%'
      )
      SELECT DISTINCT
             replace(k, 'pgrst.', '') AS key,
             v AS value
        FROM kv_settings
       ORDER BY key DESC;
    |]
    decodeSettings = HD.rowList $ (,) <$> column HD.text <*> column HD.text

column :: HD.Value a -> HD.Row a
column = HD.column . HD.nonNullable
