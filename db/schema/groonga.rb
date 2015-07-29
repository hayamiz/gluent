
def create_groonga_tables
  unless Groonga["Entries"].nil?
    Groonga["Entries"].remove
  end
  unless Groonga["Bigram"].nil?
    Groonga["Bigram"].remove
  end

  p(Groonga::Schema.create_table("Entries", type: :hash, key_type: "ShortText") do |t|
      t.text		"path"
      t.text		"title"
      t.text		"body"
      t.time		"mtime"
    end)

  p(Groonga::Schema.create_table("Bigram",
                                 type: :patricia_trie,
                                 key_type: "ShortText",
                                 default_tokenizer: "TokenBigram",
                                 :normalizer => "NormalizerAuto") do |t|
      t.index "Entries.path"
      t.index "Entries.title"
      t.index "Entries.body"
    end)
end
