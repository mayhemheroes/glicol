use proc_macro::{TokenStream};
use quote::quote;
use proc_macro2;

#[proc_macro]
pub fn handle_events(_item: TokenStream) -> TokenStream {
    let gen = quote! {
        {
            let mut p1i = paras.into_inner();
            let p: Vec<(GlicolPara, f32)> = p1i.next().unwrap().into_inner()
            .map(|pair| {
                let mut it = pair.as_str().split("@");
                let value = GlicolPara::Number(
                    it.next().unwrap().parse::<f32>().unwrap());
                let time_str = it.next().unwrap();
                let time;
                if time_str.contains("ms") {
                    time = time_str.parse::<f32>().unwrap();
                } else {
                    time = time_str.replace("s", "").parse::<f32>().unwrap();
                }
                (value, time)
            }).collect();
            chain_paras.push(vec![GlicolPara::Event(p)])
        }
    };
    gen.into()
}

#[proc_macro]
pub fn handle_pattern(_item: TokenStream) -> TokenStream {
    let gen = quote! {
        {
            let mut p1i = paras.into_inner();
            
            let p: Vec<(GlicolPara, f32)> = p1i.next().unwrap().into_inner()
            .map(|pair| {
                let mut it = pair.as_str().split("@");
                let value = GlicolPara::Number(
                    it.next().unwrap().parse::<f32>().unwrap());
                // safe, at detected on parser
                let time = it.next().unwrap().parse::<f32>().unwrap();
                (value, time)
            }).collect();
            // println!("{:?}", p1i.next().unwrap());
            let span = match p1i.next() {
                Some(r) => r.as_str().parse::<f32>().unwrap(),
                None => 1.0
            };
            chain_paras.push(vec![GlicolPara::Pattern(p, span)])
        }
    };
    gen.into()
}


#[proc_macro]
pub fn one_para_number_or_ref(item: TokenStream) -> TokenStream {
    let name = proc_macro2::TokenStream::from(item);
    let gen = quote! {
        {
            println!("node {:?}", node.as_str()); //"sin 440"
            let paras = node.into_inner().next().unwrap();
            println!("paras {:?}", paras.as_str());//"440"                                        
            chain_node_names.push(#name);
            match paras.as_rule() {
                Rule::number => {
                    chain_paras.push(vec![GlicolPara::Number(paras.as_str().parse::<f32>().unwrap())]);
                },
                Rule::reference => {
                    chain_paras.push(vec![GlicolPara::Reference(paras.as_str().to_owned())]);
                },
                _ => {}
            }
        }
    };
    gen.into()
}

#[proc_macro]
pub fn two_numbers(item: TokenStream) -> TokenStream {
    let name = proc_macro2::TokenStream::from(item);
    let gen = quote! {
        {
            println!("node {:?}", node.as_str());
            let mut iter = node.into_inner();
            let p1 = iter.next().unwrap();
            let p2 = iter.next().unwrap();
            chain_node_names.push(#name);
            chain_paras.push(vec![
                GlicolPara::Number(p1.as_str().parse::<f32>().unwrap()),
                GlicolPara::Number(p2.as_str().parse::<f32>().unwrap())
            ]);
        }
    };
    gen.into()
}

#[proc_macro]
pub fn get_one_para_from_number_or_ref(item: TokenStream) -> TokenStream {
    let name = proc_macro2::TokenStream::from(item);
    let gen = quote! {
        {
            match &paras[0] {
                GlicolPara::Number(v) => {
                    (#name::new(*v).to_boxed_nodedata(1), vec![])
                },
                GlicolPara::Reference(s) => {
                    (#name::new(0.0).to_boxed_nodedata(1), vec![s.to_owned()])
                },
                _ => {
                    unimplemented!();
                }
            }
        }
    };
    gen.into()
}
#[proc_macro]
pub fn get_one_para_from_number_or_ref2(item: TokenStream) -> TokenStream {
    let name = proc_macro2::TokenStream::from(item);
    let gen = quote! {
        {
            match &paras[0] {
                GlicolPara::Number(v) => {
                    (#name::new(*v).to_boxed_nodedata(2), vec![])
                },
                GlicolPara::Reference(s) => {
                    (#name::new(0.0).to_boxed_nodedata(2), vec![s.to_owned()])
                },
                _ => {
                    unimplemented!();
                }
            }
        }
    };
    gen.into()
}

