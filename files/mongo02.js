db = connect(mserver);
db = db.getSiblingDB('kynetx');
db.edata.ensureIndex({ken:1, key : 1});
db.edata.ensureIndex({rid : 1, ken:1, key : 1});
db.edata.ensureIndex({rid : 1, ken:1, key : 1,hashkey : 1});
