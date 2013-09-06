db = connect(mserver);
db = db.getSiblingDB('kynetx');
db.userstate.ensureIndex({ken:1,rid : 1, key : 1},{unique : true});
