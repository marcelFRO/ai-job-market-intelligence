let
    Source = Csv.Document(Web.Contents("https://docs.google.com/spreadsheets/d/e/2PACX-1vRjHhnN_KoaTvI7OG93SdHZgb0jUeHsMZpNX0975BZXYfrA1xBLxwOFCNJZO-w3foFZY0pL1yCA43BG/pub?output=csv"),[Delimiter=",", Columns=15, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Capitalized Each Word (City, Company, Title)" = Table.TransformColumns(#"Promoted Headers",{{"city", Text.Proper, type text}, {"company", Text.Proper, type text}, {"title", Text.Proper, type text}}),
    #"Replaced Foreign City Names" = Table.ReplaceValue(
    #"Capitalized Each Word (City, Company, Title)",
    each [city],
    each 
        if Text.Contains([city], "Warsaw") then "Warszawa"
        else if Text.Contains([city], "Cracow") then "Kraków"
        else if Text.Contains([city], "Krakow") then "Kraków"
        else if Text.Contains([city], "Wroclaw") then "Wrocław"
        else if Text.Contains([city], "Poland") then null
        else [city],
    Replacer.ReplaceValue,
    {"city"}
),
    #"Filtered Domestic Locations" = Table.SelectRows(
    #"Replaced Foreign City Names",
    each 
        [city] <> null 
        and [city] <> ""
        and not List.Contains(
            {
                "Aarhus", "Bangkok", "Bengaluru", "Berlin", "Bucharest", "Bukareszt",
                "Cardigos", "Copenhagen", "Cork", "Dublin", "Gütersloh", "Helsinki",
                "Hobro", "Ingolstadt", "Issy-Les-Moulineaux", "Jenbach", "Koszyce",
                "Lisbon", "Luxembourg", "Lyon", "Madrid Hybrid", "New Delhi",
                "New York", "Niort", "Paris", "Pendang", "Porto", "Pune", "Rabat",
                "Roissy-En-France", "Stockholm", "Stockholm City",
                "Stockholm Metropolitan Area", "Sztokholm", "Vilnius"
            },
            [city]
        )
),
    #"Trimmed Text" = Table.TransformColumns(#"Filtered Domestic Locations",{{"title", Text.Trim, type text}}),
    #"Removed Duplicates (Link)" = Table.Distinct(#"Trimmed Text", {"link"}),
    #"Removed Duplicates (Title, City, Company)" = Table.Distinct(#"Removed Duplicates (Link)", {"title", "city", "company"}),
    #"Workplace Type Normalisation" = Table.ReplaceValue(
    #"Removed Duplicates (Title, City, Company)",
    each [workplace_type],
    each 
        if [workplace_type] = "Praca hybrydowa" then "hybrid"
        else if [workplace_type] = "Praca mobilna" then null
        else if [workplace_type] = "Praca stacjonarna" then "office"
        else if [workplace_type] = "Praca zdalna" then "remote"
        else [workplace_type],
    Replacer.ReplaceValue,
    {"workplace_type"}
),
    #"Workplace Cleanup" = Table.SelectRows(#"Workplace Type Normalisation", each ([workplace_type] <> null)),
    #"Capitalized Each Word (Workplace)" = Table.TransformColumns(#"Workplace Cleanup",{{"workplace_type", Text.Proper, type text}}),
    #"Removed Columns" = Table.RemoveColumns(#"Capitalized Each Word (Workplace)",{"timestamp", "link", "published_at"}),
    #"Employment Type Normalisation" = Table.ReplaceValue(
    #"Removed Columns",
    each [employment_type],
    each 
        if [employment_type] = "Kontrakt B2B" then "B2B"
        else if [employment_type] = "mandate_contract" then "Mandate"
        else if [employment_type] = "Umowa zlecenie" then "Mandate"
        else if [employment_type] = "Umowa o dzieło" then "Mandate"
        else if [employment_type] = "Umowa o pracę" then "Permanent"
        else if [employment_type] = "Umowa o pracę tymczasową" then "Temporary"
        else if [employment_type] = "Umowa na zastępstwo" then "Temporary"
        else if [employment_type] = "Umowa o staż / praktyki" then "Mandate"
        else if [employment_type] = "internship" then "Mandate"
        else [employment_type],
    Replacer.ReplaceValue,
    {"employment_type"}
),
    #"Employment Type cleanup" = Table.SelectRows(#"Employment Type Normalisation", each ([employment_type] <> null)),
    #"Capitalized Each Word (Employment_type)" = Table.TransformColumns(#"Employment Type cleanup",{{"employment_type", Text.Proper, type text}}),
    #"Experience Level Normalisation" = Table.ReplaceValue(
    #"Capitalized Each Word (Employment_type)",
    each [experience_level],
    each 
        if [experience_level] = "Praktykant / Praktykantka - stażysta / Stażystka" then "Junior"
        else if [experience_level] = "Asystent / Asystentka" then "Junior"
        else if [experience_level] = "Młodszy specjalista / Młodsza specjalistka (junior)" then "Junior"
        else if [experience_level] = "junior" then "Junior"
        else if [experience_level] = "Specjalista / Specjalistka (mid / Regular)" then "Mid"
        else if [experience_level] = "mid" then "Mid"
        else if [experience_level] = "Starszy specjalista / Starsza specjalistka (senior)" then "Senior"
        else if [experience_level] = "senior" then "Senior"
        else if [experience_level] = "Ekspert / Ekspertka" then "Senior"
        else if [experience_level] = "Kierownik / Kierowniczka - koordynator / Koordynatorka" then "Lead/Manager"
        else if [experience_level] = "Menedżer / Menedżerka" then "Lead/Manager"
        else if [experience_level] = "Dyrektor / Dyrektorka" then "Lead/Manager"
        else if [experience_level] = "c_level" then "Lead/Manager"
        else [experience_level],
    Replacer.ReplaceValue,
    {"experience_level"}
),
    #"Source Normalisation" = Table.ReplaceValue(#"Experience Level Normalisation",
    each [source],
    each 
        if [source] = "pracuj.pl" then "Pracuj"
        else if [source] = "justjoin.it" then "Just Join IT"
        else [source],
    Replacer.ReplaceValue,
    {"source"}
),
    #"Added Index" = Table.AddIndexColumn(#"Source Normalisation", "Index", 1, 1, Int64.Type),
    #"Reordered Columns" = Table.ReorderColumns(#"Added Index",{"Index", "skills", "category", "title", "city", "company", "experience_level", "workplace_type", "salary_from", "salary_to", "salary_currency", "employment_type", "source"}),
    #"Renamed Columns" = Table.RenameColumns(#"Reordered Columns",{{"Index", "OfferID"}}),
    #"Company Name Normalisation" = Table.TransformColumns(
    #"Renamed Columns",
    {{"company", each 
        let
            quoteChar = Character.FromNumber(34),
            
            // 1. Usuń cudzysłowy na początku/końcu
            noQuotes = Text.Trim(_, {quoteChar}),
            
            // 2. Usuń wszystko w nawiasach
            noBrackets = 
                let
                    parts = Text.Split(noQuotes, "("),
                    firstPart = parts{0},
                    rest = if List.Count(parts) > 1 
                           then List.Skip(parts, 1) 
                           else {},
                    afterBrackets = List.Transform(rest, each 
                        let split = Text.Split(_, ")") 
                        in if List.Count(split) > 1 then split{1} else "")
                in
                    Text.Combine({firstPart} & afterBrackets, ""),
            
            // 3. Usuń wszystko po " - " LUB " – " (zwykły lub długi myślnik)
            noDashSuffix = 
                if Text.Contains(noBrackets, " – ") 
                then Text.BeforeDelimiter(noBrackets, " – ")
                else if Text.Contains(noBrackets, " - ") 
                then Text.BeforeDelimiter(noBrackets, " - ") 
                else noBrackets,
            
            // 4. Usuń wszystko od " Oddział " w dół (oddziały firm)
            noOddzial = 
                if Text.Contains(noDashSuffix, " Oddział ") 
                then Text.BeforeDelimiter(noDashSuffix, " Oddział ")
                else noDashSuffix,
            
            // 5. Normalizacja wariantów form prawnych
            normalized = List.Accumulate(
                {
                    {"Spółka Z Ograniczoną Odpowiedzialnością", "Sp. z o.o."},
                    {"Spółka Z O.O.", "Sp. z o.o."},
                    {"Spółka Z O.O", "Sp. z o.o."},
                    {"Spółka Z O. O.", "Sp. z o.o."},
                    {"Spółka Z O. O", "Sp. z o.o."},
                    {"Sp. z o.o. Sp. K.", "Sp. z o.o. Sp.K."},
                    {"Sp. z o.o. Sp. K", "Sp. z o.o. Sp.K."},
                    {"Sp. z o.o. Sk", "Sp. z o.o. Sp.K."},
                    {"Sp. z o.o. SK", "Sp. z o.o. Sp.K."},
                    {"Sp.Z.O.O", "Sp. z o.o."},
                    {"Sp.Z O O", "Sp. z o.o."},
                    {"Sp. Z O. O.", "Sp. z o.o."},
                    {"Sp. Z O. O", "Sp. z o.o."},
                    {"Sp. Z O.O.", "Sp. z o.o."},
                    {"Sp. Z O.O", "Sp. z o.o."},
                    {"Sp. Z O.o.", "Sp. z o.o."},
                    {"Sp. Z O.o", "Sp. z o.o."},
                    {"Sp Z O.O.", "Sp. z o.o."},
                    {"Sp Z O.O", "Sp. z o.o."},
                    {"Sp Z O. O.", "Sp. z o.o."},
                    {"Sp Z O. O", "Sp. z o.o."},
                    {"Sp Z O O", "Sp. z o.o."},
                    {"Sp. z o.o", "Sp. z o.o."},
                    {"Sp. Zoo", "Sp. z o.o."},
                    {"Sp Zoo", "Sp. z o.o."},
                    {"Spzoo", "Sp. z o.o."},
                    {"Spółka Akcyjna", "S.A."},
                    {"S. A.", "S.A."},
                    {" Sa ", " S.A. "},
                    {" Sa.", " S.A."},
                    {" S.A ", " S.A. "},
                    {"B. V.", "B.V."},
                    {"B.v.", "B.V."}
                },
                noOddzial,
                (state, current) => Text.Replace(state, current{0}, current{1})
            ),
            
            // 6. Po normalizacji: jeśli kończy się "S.A" lub "Sa" (bez kropki na końcu), dodaj kropkę
            withTrailingDot = 
                if Text.EndsWith(normalized, " S.A") then normalized & "."
                else if Text.EndsWith(normalized, " Sa") then Text.Start(normalized, Text.Length(normalized) - 3) & " S.A."
                else if Text.EndsWith(normalized, " B.V") then normalized & "."
                else normalized,
            
            // 7. Czyść podwójne kropki
            cleanedDots = Text.Replace(withTrailingDot, "..", "."),
            
            // 8. Usuń typowe formy prawne na końcu nazwy
            removed = List.Accumulate(
                {
                    " Sp. z o.o. Sp.K.",
                    " Sp. z o.o. Spółka Komandytowa",
                    " Sp. K.",
                    " Sp.K.",
                    " Spółka Komandytowa",
                    " Sp. z o.o.",
                    " S.A.",
                    " S.K.A.",
                    " Spółka Komandytowo-Akcyjna",
                    " Sp. J.",
                    " Sp.J.",
                    " Spółka Jawna",
                    " S.C.",
                    " Sc.",
                    " Spółka Cywilna",
                    " P.S.A.",
                    " Prosta Spółka Akcyjna",
                    " B.V.",
                    " Bv",
                    " Branch",
                    " Ltd.",
                    " Ltd",
                    " Limited",
                    " Inc.",
                    " Inc",
                    " Llc",
                    " LLC",
                    " Gmbh",
                    " GmbH",
                    " Ag",
                    " AG",
                    " Group",
                    " Polska",
                    " Poland",
                    " W Polsce",
                    " w Polsce"
                },
                cleanedDots,
                (state, current) => 
                    if Text.EndsWith(state, current) 
                    then Text.Trim(Text.Start(state, Text.Length(state) - Text.Length(current)))
                    else state
            ),
            
            // 9. Końcowy trim — wiszące znaki interpunkcyjne, spacje, cudzysłowy
            trimmed = Text.TrimEnd(Text.Trim(removed), {",", "-", " ", ".", "/", quoteChar}),
            
            // 10. Mapowanie konkretnych firm (entity resolution dla znanych brandów)
            brandMapped = 
                if Text.StartsWith(trimmed, "Bnp Paribas") then "BNP Paribas"
                else if trimmed = "Pko Bank Polski" then "PKO Bank Polski"
                else if trimmed = "Pkp Polskie Linie Kolejowe" then "PKP Polskie Linie Kolejowe"
                else if trimmed = "Axa Avanssur" then "AXA"
                else if Text.StartsWith(trimmed, "Axa") then "AXA"
                else if Text.StartsWith(trimmed, "Compensa") then "Compensa"
                else if Text.StartsWith(trimmed, "Danish Crown") then "Danish Crown"
                else if Text.StartsWith(trimmed, "Loyalty Partner") then "Loyalty Partner"
                else if Text.StartsWith(trimmed, "Lumicode") then "Lumicode"
                else if Text.StartsWith(trimmed, "Opgroen Assuradeuren") then "Opgroen Assuradeuren"
                else if Text.StartsWith(trimmed, "Fun Crafters") then "Fun Crafters"
                else if Text.StartsWith(trimmed, "Sollers Consulting") then "Sollers Consulting"
                else if Text.StartsWith(trimmed, "Fashiontex") then "Fashiontex"
                else trimmed
        in
            brandMapped, type text}}
),
    #"Changed Type" = Table.TransformColumnTypes(#"Company Name Normalisation",{{"city", type text}, {"experience_level", type text}, {"source", type text}, {"salary_to", type number}, {"salary_from", type number}}),
    #"Uppercased Text" = Table.TransformColumns(#"Changed Type",{{"salary_currency", Text.Upper, type text}}),
    #"Currency change" = Table.ReplaceValue(
    #"Uppercased Text",
    each [salary_currency],
    each 
        if [salary_currency] = "EUR" or [salary_currency] = "USD" then "PLN"
        else [salary_currency],
    Replacer.ReplaceValue,
    {"salary_currency"}
),
    #"Salary consistency filter" = Table.SelectRows(
    #"Currency change",
    each 
        [salary_from] = null 
        or [salary_to] = null 
        or [salary_to] / [salary_from] <= 20
),
    #"Salary type" = Table.AddColumn(
    #"Salary consistency filter",
    "salary_format",
    each 
        if [salary_from] = null then null
        else if [salary_from] < 500 then "Hourly"
        else if [salary_from] < 2000 then "Daily"
        else if [salary_from] < 100000 then "Monthly"
        else "Yearly",
    type text
),
    #"Salary from monthly" = Table.AddColumn(
    #"Salary type",
    "salary_from_monthly",
    each 
        if [salary_format] = null then null
        else if [salary_format] = "Hourly" then [salary_from] * 168
        else if [salary_format] = "Daily" then [salary_from] * 21
        else if [salary_format] = "Yearly" then [salary_from] / 12
        else [salary_from],
    type number
),
    #"Salary to monthly" = Table.AddColumn(
    #"Salary from monthly",
    "salary_to_monthly",
    each 
        if [salary_format] = null then null
        else if [salary_format] = "Hourly" then [salary_to] * 168
        else if [salary_format] = "Daily" then [salary_to] * 21
        else if [salary_format] = "Yearly" then [salary_to] / 12
        else [salary_to],
    type number
),
    #"Reordered Columns (Salary)" = Table.ReorderColumns(#"Salary to monthly",{"OfferID", "category", "title", "city", "company", "experience_level", "workplace_type", "salary_from", "salary_from_monthly", "salary_to", "salary_to_monthly", "salary_currency", "employment_type", "source"}),
    #"Removed Currency" = Table.RemoveColumns(#"Reordered Columns (Salary)",{"salary_currency"}),
    #"Title Normalisation" = Table.TransformColumns(
    #"Removed Currency",
    {{"title", each 
        let
            // Lista wszystkich wzorców gender które chcemy usunąć
            allPatterns = {
                // Trzy elementy
                "K/M/X", "K/M/N", "K/M/D", "K/M/Os", "K/M/Os.", "K/M/*",
                "M/K/X", "M/K/N", "M/K/D", "M/K/Os", "M/K/Os.", "M/K/*",
                "F/M/X", "F/M/N", "F/M/D", "F/M/*",
                "M/F/X", "M/F/N", "M/F/D", "M/F/*",
                "K/F/X", "K/F/D",
                "F/K/X", "F/K/D",
                "She/He/They", "He/She/They",
                "K / M / X", "M / K / X", "K / M / N", "M / K / N",
                "K, M, X", "M, K, X",
                
                // Dwa elementy
                "K/M", "M/K", "F/M", "M/F", "K/F", "F/K",
                "K / M", "M / K", "F / M", "M / F",
                "K,M", "M,K", "K, M", "M, K",
                "She/He", "He/She"
            },
            
            input = _,
            
            // 1. Usuń wzorce w nawiasach okrągłych: (K/M), ( K/M), (K/M ), ( K/M )
            withoutRound = List.Accumulate(
                allPatterns,
                input,
                (state, pattern) => 
                    let
                        variants = {
                            "(" & pattern & ")",
                            "( " & pattern & ")",
                            "(" & pattern & " )",
                            "( " & pattern & " )"
                        }
                    in
                        List.Accumulate(
                            variants,
                            state,
                            (s, v) => Text.Replace(s, v, "")
                        )
            ),
            
            // 2. Usuń wzorce w nawiasach kwadratowych: [K/M]
            withoutSquare = List.Accumulate(
                allPatterns,
                withoutRound,
                (state, pattern) => Text.Replace(state, "[" & pattern & "]", "")
            ),
            
            // 3. Usuń wzorce po pipe na końcu: " | F/M/D", "| M/K"
            withoutPipe = List.Accumulate(
                allPatterns,
                withoutSquare,
                (state, pattern) => 
                    if Text.EndsWith(state, " | " & pattern) 
                    then Text.Start(state, Text.Length(state) - Text.Length(" | " & pattern))
                    else if Text.EndsWith(state, "| " & pattern)
                    then Text.Start(state, Text.Length(state) - Text.Length("| " & pattern))
                    else state
            ),
            
            // 4. Usuń wzorce na końcu po spacji: " M/K", " K/M/X"
            withoutTrailing = List.Accumulate(
                allPatterns,
                withoutPipe,
                (state, pattern) => 
                    if Text.EndsWith(state, " " & pattern) 
                    then Text.Start(state, Text.Length(state) - Text.Length(" " & pattern))
                    else state
            ),
            
            // 5. Cleanup
            noDoubleSpaces = Text.Replace(withoutTrailing, "  ", " "),
            final = Text.TrimEnd(Text.Trim(noDoubleSpaces), {",", "-", " ", "|", "."})
        in
            final, type text}}
),
    #"Renamed Columns1" = Table.RenameColumns(#"Title Normalisation",{{"OfferID", "_offerID"}, {"source", "_source"}}),
    #"Replaced data quality -> other" = Table.ReplaceValue(#"Renamed Columns1","data quality","other",Replacer.ReplaceText,{"category"}),
    #"Renamed Columns2" = Table.RenameColumns(#"Replaced data quality -> other",{{"_source", "Source"}, {"category", "Category"}, {"workplace_type", "Workplace Type"}, {"city", "City"}, {"experience_level", "Level of Experience"}, {"title", "Title"}, {"employment_type", "Employment Type"}, {"company", "Company"}, {"salary_from_monthly", "Salary From"}, {"salary_to_monthly", "Salary to"}}),
    #"Added Workplace Order" = Table.AddColumn(
    #"Renamed Columns2",
    "Order Workplace",
    each 
        if [Workplace Type] = "Office" then 1
        else if [Workplace Type] = "Hybrid" then 2
        else if [Workplace Type] = "Remote" then 3
        else 4,
    Int64.Type
),
    #"Added Experience Order" = Table.AddColumn(
    #"Added Workplace Order",
    "Order Experience",
    each 
        if [Level of Experience] = "Junior" then 1
        else if [Level of Experience] = "Mid" then 2
        else if [Level of Experience] = "Senior" then 3
        else if [Level of Experience] = "Lead/Manager" then 4
        else 5,
    Int64.Type
),
    #"Added Employment Order" = Table.AddColumn(
    #"Added Experience Order",
    "Order Employment",
    each 
        if [Employment Type] = "Temporary" then 1
        else if [Employment Type] = "Mandate" then 2
        else if [Employment Type] = "B2B" then 3
        else if [Employment Type] = "Permanent" then 4
        else if [Employment Type] = "Any" then 5
        else 6,
    Int64.Type
),
    #"Added Salary Bin" = Table.AddColumn(
    #"Added Employment Order",
    "Salary Bin",
    each 
        if [Salary From] = null then null
        else if [Salary From] < 5000 then "0-5K"
        else if [Salary From] < 10000 then "5-10K"
        else if [Salary From] < 15000 then "10-15K"
        else if [Salary From] < 20000 then "15-20K"
        else if [Salary From] < 25000 then "20-25K"
        else if [Salary From] < 30000 then "25-30K"
        else if [Salary From] < 35000 then "30-35K"
        else if [Salary From] < 40000 then "35-40K"
        else if [Salary From] < 50000 then "40-50K"
        else "50K+",
    type text
),
    #"Added Salary Bin Order" = Table.AddColumn(
    #"Added Salary Bin",
    "Salary Bin Order",
    each 
        if [Salary From] = null then null
        else if [Salary From] < 5000 then 1
        else if [Salary From] < 10000 then 2
        else if [Salary From] < 15000 then 3
        else if [Salary From] < 20000 then 4
        else if [Salary From] < 25000 then 5
        else if [Salary From] < 30000 then 6
        else if [Salary From] < 35000 then 7
        else if [Salary From] < 40000 then 8
        else if [Salary From] < 50000 then 9
        else 10,
    Int64.Type
),
    #"Renamed Columns3" = Table.RenameColumns(#"Added Salary Bin Order",{{"Salary Bin Order", "Order Salary Bin"}})
in
    #"Renamed Columns3"
