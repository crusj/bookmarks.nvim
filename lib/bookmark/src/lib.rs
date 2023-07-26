use md5::Digest;
use mlua::prelude::*;
use mlua::Value;
use mlua::{Lua, LuaSerdeExt};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs::File;
use std::io::{BufRead, BufReader};

#[mlua::lua_module]
fn bookmark(lua: &Lua) -> LuaResult<LuaTable> {
    let export = lua.create_table()?;
    export.set(
        "fix",
        lua.create_function(|lua, (file_path, bookmarks): (String, LuaTable)| {
            let value = get_changes(lua, (file_path, bookmarks)).unwrap();
            let value = lua.to_value(&value);
            value
        })?,
    )?;
    export.set("get_md5", lua.create_function(get_md5)?)?;
    Ok(export)
}
#[derive(Clone, Serialize, Deserialize)]
struct Item {
    filename: String,
    description: String,
    fre: i32,
    id: String,
    line_md5: String,
    line: i32,
    updated_at: i32,
}

fn get_changes(lua: &Lua, (file_path, bookmarks): (String, LuaTable)) -> LuaResult<Vec<Item>> {
    let mut ret: Vec<Item> = Vec::new();
    let mut v: HashMap<String, Vec<Item>> = HashMap::new();
    for pair in bookmarks.pairs::<Value, Value>() {
        let (_, value) = pair.unwrap();
        if let Value::Table(value) = value {
            let item = Item {
                filename: value.get("filename").unwrap(),
                description: value.get("description").unwrap(),
                fre: value.get("fre").unwrap(),
                id: value.get("id").unwrap(),
                line: value.get("line").unwrap(),
                line_md5: value.get("line_md5").unwrap(),
                updated_at: value.get("updated_at").unwrap(),
            };

            if v.contains_key(&item.line_md5) {
                v.get_mut(&item.line_md5).unwrap().push(item);
            } else {
                v.insert(item.line_md5.clone(), vec![item]);
            }
        }
    }

    if v.is_empty() {
        return Ok(ret);
    }

    // 将文件相同内容(md5)进行分组，值为行号
    let vv = file_md5(file_path);
    // 遍历现有的书签,通过比较书签md5以及对应的行号，做出动作
    for (key, value) in v {
        // 文件存在与书签相同的内容
        if let Some(lines) = vv.get(&key) {
            // 存在且唯一，原来书签只能第一个有效，该书签对应的行号为文件对应的行号
            if lines.len() == 1 {
                let mut item = value.get(0).cloned().unwrap();
                item.line = lines.get(0).unwrap().clone();
                item.id = format!(
                    "{:x}",
                    md5::compute(&format!("{}:{}", item.filename, item.line))
                );
                ret.push(item);
            } else {
                // 存在且原来书签只有一个，寻找是否存在于原来书签相同的行号，如果存在为改书签，否则为第一个文件分组行
                if value.len() == 1 {
                    let mut item = value.get(0).cloned().unwrap();
                    let mut flag = false;
                    for line in lines {
                        if &item.line == line {
                            flag = true;
                            break;
                        }
                    }
                    if !flag {
                        item.line = lines.get(0).unwrap().clone();
                    }
                    item.id = format!(
                        "{:x}",
                        md5::compute(&format!("{}:{}", item.filename, item.line))
                    );
                    ret.push(item);
                } else {
                    // 多对多
                    let mut used_line: HashMap<i32, bool> = HashMap::new();
                    for item in value.iter() {
                        for line in lines {
                            if &item.line == line && !used_line.contains_key(&item.line) {
                                ret.push(item.clone());
                                used_line.insert(*line, true);
                            }
                        }
                    }

                    // 第二次为更新找不到对应行号的书签,即原来的行可能发生了变化
                    for item in value.iter() {
                        if used_line.contains_key(&item.line) {
                            continue;
                        }
                        for line in lines {
                            if used_line.contains_key(line) {
                                continue;
                            }
                            let mut item = item.clone();
                            item.id = format!(
                                "{:x}",
                                md5::compute(&format!("{}:{}", item.filename, item.line))
                            );
                            item.line = *line;
                            ret.push(item);
                            used_line.insert(*line, true);
                            break;
                        }
                    }
                }
            }
        }
    }

    Ok(ret)
}

fn file_md5(file_path: String) -> HashMap<String, Vec<i32>> {
    let mut ret: HashMap<String, Vec<i32>> = HashMap::new();
    if let Ok(file) = File::open(file_path) {
        let reader = BufReader::new(file);
        let mut number = 0;
        for line in reader.lines() {
            number += 1;
            if let Ok(line_content) = line {
                let md5_hash = calculate_md5_hash(&line_content);
                let md5_hash = format!("{:x}", md5_hash);
                if ret.contains_key(&md5_hash) {
                    ret.get_mut(&md5_hash).unwrap().push(number);
                } else {
                    ret.insert(md5_hash, vec![number]);
                }
            }
        }
    }

    ret
}

fn calculate_md5_hash(input: &str) -> Digest {
    md5::compute(input)
}

fn get_md5(_: &Lua, str: String) -> LuaResult<String> {
    Ok(format!("{:x}", md5::compute(str)))
}
