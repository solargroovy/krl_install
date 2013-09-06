db = connect(mserver);
db = db.getSiblingDB('kynetx');
print("Org: " + orgname);
printjson(db.adminCommand('listDatabases'));
db.dictionary.update({'name' : orgname},{$inc : {'count' : 1}},{upsert : true});
db.dictionary.ensureIndex({ttl1 : 1},{expireAfterSeconds : 60});
db.dictionary.ensureIndex({ttl5 : 1},{expireAfterSeconds : 300});
