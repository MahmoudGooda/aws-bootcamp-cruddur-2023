from lib.db import db

class ReplyToActivityUuidMigration:
  def migrate_sql():
    data = """
    ALTER TABLE activities
    ALTER COLUMN reply_to_activity_uuid TYPE uuid USING reply_to_activity_uuid::uuid;
    """
    return data
  def rollback_sql():
    data = """
    ALTER TABLE activities
    ALTER COLUMN reply_to_activity_uuid TYPE integer USING (reply_to_activity_uuid::integer);
    """
    return data

  def migrate():
    db.query_commit(ReplyToActivityUuidMigration.migrate_sql(),{
    })

  def rollback():
    db.query_commit(ReplyToActivityUuidMigration.rollback_sql(),{
    })

migration = ReplyToActivityUuidMigration