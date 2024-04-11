///////////////////// IF ///////////////////////////

bool __g(final num x, final num y) => x > y;
bool __l(final num x, final num y) => x < y;
bool __geq(final num x, final num y) => x >= y;
bool __leq(final num x, final num y) => x <= y;
bool __eq(final num x, final num y) => x == y;
bool __neq(final num x, final num y) => x != y;

bool Function(num, num)? resolveIfCallback(final String op){
  if(op == ">"){
    return __g;
  }
  else if(op == "<"){
    return __l;
  }
  else if(op == ">="){
    return __geq;
  }
  else if(op == "<="){
    return __leq;
  }
  else if(["!=", "<>"].contains(op)){
    return __eq;
  }
  else if(["=", "=="].contains(op)){
    return __neq;
  }
  return null;
}

////////////////////////////////////////////////////