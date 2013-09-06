db = connect(mserver);
db = db.getSiblingDB('kynetx');
db.metrics.ensureIndex({eid : 1});
