function compile(code) {
  var sexp = Opal.Opal.Parser.$new().$parse(code);
  return Opal.Object.__proto__.$block_to_pos_to_result(sexp);
}
console.log(compile("puts 3\nputs 4\n"));
