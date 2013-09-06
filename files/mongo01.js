db = connect(mserver);
db = db.getSiblingDB('kynetx');
db.appdata.ensureIndex({rid : 1});
db.appdata.ensureIndex({rid : 1,key : 1});
db.appdata.ensureIndex({rid : 1,key : 1,hashkey : 1});


