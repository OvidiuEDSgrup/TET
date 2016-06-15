--***
CREATE procedure wIaPar @sesiune varchar(50), @filtruTipParametru varchar(2), @filtruParametru varchar(9)  
as  
select rtrim(Parametru) as parametru, convert(varchar(1),Val_logica) as val_logica, convert(decimal(9,2),Val_numerica) as val_numerica, rtrim(Val_alfanumerica) as val_alfanumerica from par  
where Tip_parametru=@filtruTipParametru and Parametru like @filtruParametru+'%' 
order by rtrim(Parametru)
for xml raw
