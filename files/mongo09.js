db = connect(mserver);
db = db.getSiblingDB('kynetx');
db.tokens.ensureIndex({ktoken : 1},{unique : true});
db.tokens.ensureIndex({endpoint_id : 1},{unique : true});
db.tokens.ensureIndex({user_id : 1},{sparse : true});
db.tokens.ensureIndex({last_active : 1});
db.tokens.ensureIndex({ken : 1});
db.tokens.ensureIndex({token_name : 1});
db.tokens.ensureIndex({endpoint_type : 1});
db.tokens.ensureIndex({ttl5 : 1},{expireAfterSeconds : 600});
