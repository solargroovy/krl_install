db = connect(mserver);
db = db.getSiblingDB('kynetx');
db.schedev.ensureIndex({cron_id : 1});
db.schedev.ensureIndex({ken : 1});
db.schedev.ensureIndex({expired : 1},{expireAfterSeconds : 120});
