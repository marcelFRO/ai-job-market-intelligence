let
    Source = Offers,
    #"Removed Other Columns" = Table.SelectColumns(Source, {"_offerID", "skills"}),
    #"Split Column by Delimiter" = Table.SplitColumn(
        #"Removed Other Columns", 
        "skills", 
        Splitter.SplitTextByDelimiter(",", QuoteStyle.Csv), 
        {"skills.1", "skills.2", "skills.3", "skills.4", "skills.5", "skills.6", "skills.7", "skills.8", "skills.9", "skills.10", "skills.11", "skills.12", "skills.13", "skills.14", "skills.15", "skills.16", "skills.17", "skills.18", "skills.19", "skills.20", "skills.21", "skills.22"}
    ),
    #"Changed Type" = Table.TransformColumnTypes(#"Split Column by Delimiter",{{"skills.1", type text}, {"skills.2", type text}, {"skills.3", type text}, {"skills.4", type text}, {"skills.5", type text}, {"skills.6", type text}, {"skills.7", type text}, {"skills.8", type text}, {"skills.9", type text}, {"skills.10", type text}, {"skills.11", type text}, {"skills.12", type text}, {"skills.13", type text}, {"skills.14", type text}, {"skills.15", type text}, {"skills.16", type text}, {"skills.17", type text}, {"skills.18", type text}, {"skills.19", type text}, {"skills.20", type text}, {"skills.21", type text}, {"skills.22", type text}}),
    #"Unpivoted Other Columns" = Table.UnpivotOtherColumns(#"Changed Type", {"_offerID"}, "Attribute", "Value"),
    #"Removed Attribute" = Table.RemoveColumns(#"Unpivoted Other Columns",{"Attribute"}),
    #"Trimmed Value" = Table.TransformColumns(#"Removed Attribute",{{"Value", Text.Trim, type text}}),
    #"Capitalized Each Word" = Table.TransformColumns(#"Trimmed Value",{{"Value", Text.Proper, type text}}),
    #"List of Exceptions" = Table.ReplaceValue(
        #"Capitalized Each Word",
        each [Value],
        each 
            if [Value] = "Sql" then "SQL"
            else if [Value] = "Pytorch" then "PyTorch"
            else if [Value] = "Tensorflow" then "TensorFlow"
            else if [Value] = "Aws" then "AWS"
            else if [Value] = "Gcp" then "GCP"
            else if [Value] = "Powerbi" then "Power BI"
            else if [Value] = "Power Bi" then "Power BI"
            else if [Value] = "Css" then "CSS"
            else if [Value] = "Html" then "HTML"
            else if [Value] = "Javascript" then "JavaScript"
            else if [Value] = "Typescript" then "TypeScript"
            else if [Value] = "Mlops" then "MLOps"
            else if [Value] = "Devops" then "DevOps"
            else if [Value] = "Etl" then "ETL"
            else if [Value] = "Api" then "API"
            else if [Value] = "Nlp" then "NLP"
            else if [Value] = "Ai" then "AI"
            else if [Value] = "Ml" then "Machine Learning"
            else if [Value] = "Bi" then "BI"
            else [Value],
        Replacer.ReplaceValue,
        {"Value"}
    ),
    #"Filtered Blank" = Table.SelectRows(#"List of Exceptions", each ([Value] <> "")),
    #"Renamed Skills" = Table.RenameColumns(#"Filtered Blank",{{"Value", "Skill"}})
in
    #"Renamed Skills"
