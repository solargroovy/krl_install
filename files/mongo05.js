db = connect(mserver);
db = db.getSiblingDB('kynetx');
db.kpds.ensureIndex({ken:1, hashkey : 1});
db.kpds.ensureIndex({ken:1});
