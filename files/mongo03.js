db = connect(mserver);
db = db.getSiblingDB('kynetx');
db.event.ensureIndex({ken:1, rid : 1,rulename : 1},{unique : 1});
