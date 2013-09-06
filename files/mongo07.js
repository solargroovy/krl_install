db = connect(mserver);
db = db.getSiblingDB('kynetx');
db.ruleset.ensureIndex({hashkey : 1});
db.ruleset.ensureIndex({rid : 1});
db.ruleset.ensureIndex({rid : 1, hashkey : 1});
