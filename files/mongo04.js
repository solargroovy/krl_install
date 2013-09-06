db = connect(mserver);
db = db.getSiblingDB('kynetx');
db.kens.ensureIndex({user_id : 1});
db.kens.ensureIndex({last_active : 1})
db.kens.ensureIndex({username : 1})
