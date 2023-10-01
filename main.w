bring cloud;
bring ex;
bring util;

let api = new cloud.Api();
let userTable = new ex.DynamodbTable({
  name: "users",
  attributeDefinitions: {
    "id": "S"
  },
  hashKey: "id"
});

api.get("/users/{id}", inflight (request: cloud.ApiRequest): cloud.ApiResponse => {
  let user = userTable.getItem({"id": request.vars.get("id")});
  return cloud.ApiResponse {
    status: 200,
    body: Json.stringify(user)
  };
});

api.post("/users", inflight (request: cloud.ApiRequest): cloud.ApiResponse => {
  // リクエストボディからユーザー名を取得
  if let body = request.body {
    let id = util.uuidv4();
    let parsedBody = Json.parse(body);
    let userName = parsedBody.get("name").asStr();

    if userName == "" {
      return cloud.ApiResponse {
        status: 400,
        body: "name required."
      };
    }

    try {
      userTable.putItem({
        "id": id,
        "name": userName
      }, {
        // 上書きをしない条件を記載 
        // see: https://www.winglang.io/docs/standard-library/ex/api-reference#conditionexpressionoptional-
        // see: https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/developerguide/Expressions.ConditionExpressions.html
        conditionExpression: "attribute_not_exists(id)"
      });
    } catch e {
      log(e);
      return cloud.ApiResponse {
        status: 400,
        body: "id duplicated."
      };
    }
    return cloud.ApiResponse {
      status: 200,
      body: "SUCCESS"
    };
  }

  // bodyがない場合
  // NOTE: 本来bodyがない場合をバリデーションで取り除きたかったが、型推論が効かないため書きづらくこのようにした
  return cloud.ApiResponse {
    status: 400,
    body: "request body required."
  };
});

api.put("/users/{id}", inflight (request: cloud.ApiRequest): cloud.ApiResponse => {
  let id =  request.vars.get("id");

  if let body = request.body {
    let parsedBody = Json.parse(body);
    let userName = parsedBody.get("name").asStr();

    if userName == "" {
      return cloud.ApiResponse {
        status: 400,
        body: "name required."
      };
    }

    try {
      userTable.putItem({
        "id": id,
        "name": userName
      }, {
        // 上書きのみの条件
        conditionExpression: "attribute_exists(id)"
      });
    } catch e {
      log(e);
      return cloud.ApiResponse {
        status: 400,
        body: "id not exists."
      };            
    }
    return cloud.ApiResponse {
      status: 200,
      body: "SUCCESS"
    };      

  }

  // bodyがない場合
  // NOTE: 本来bodyがない場合をバリデーションで取り除きたかったが、型推論が効かないため書きづらくこのようにした
  return cloud.ApiResponse {
    status: 400,
    body: "request body required."
  };
});

api.delete("/users/{id}", inflight (request: cloud.ApiRequest): cloud.ApiResponse => {
  let id =  request.vars.get("id");
  userTable.deleteItem({"id": id});
  return cloud.ApiResponse {
    status: 200,
    body: "SUCCESS"
  };
});