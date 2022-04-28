// use pest::Parser;
// use pest::iterators::Pairs;
use glicol_parser::*;

fn main() {
    println!("{:?}", get_ast(r#"o: sin "440@60" "#));
    // println!("{:?}", get_ast(r#"o: sin freq=\8n _ scale=50 add=60 "#));
    // get_ast(input);
    // let line = GlicolParser::parse(Rule::block, input);
    // println!("{:?}", line);
    // }
}