
def create_groonga_tables
  unless Groonga["Entries"].nil?
    Groonga["Papers"].remove
  end
  unless Groonga["Bigram"].nil?
    Groonga["Bigram"].remove
  end

  p(Groonga::Schema.create_table("Entries", type: :hash, key_type: "Int32") do |t|
      t.text		"title"
      t.text		"body"
      t.text		"path"
      t.time		"mtime"
    end)

  p(Groonga::Schema.create_table("Bigram",
                                 type: :patricia_trie,
                                 key_type: "ShortText",
                                 default_tokenizer: "TokenBigram",
                                 :normalizer => "NormalizerAuto") do |t|
      t.index "Entries.title"
      t.index "Entries.body"
      t.index "Entries.path"
    end)
end
