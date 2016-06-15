--***
create function fParRepUtiliz()
returns @parrep table (id int,val_alfanumerica varchar(200),parametru varchar(20),val_numerica decimal(20,2))
as 
begin
		/**	se ia @LMutiliz=locul de munca cel mai inferior posibil care sa le unifice pe toate din proprietatile utilizatorului*/
	declare @utilizator varchar(20)
	select @utilizator=dbo.fiautilizator('')
	declare @LMutiliz varchar(20)
	select top 1 @LMutiliz=lm.cod 
		from lm where exists (select 1 from lmfiltrare f where utilizator=@utilizator)
			and not exists (select 1 from lmfiltrare f where utilizator=@utilizator and f.cod not like rtrim(lm.Cod)+'%') 
		order by lm.nivel desc, lm.cod desc
		/**	se cauta locul de munca avand cel mai mic nivel care sa includa @LMUtiliz si sa aiba semnaturi */
	declare @primLMcuSemnaturi varchar(20)
	select top 1 @primLMcuSemnaturi=lm.Cod from lm inner join proprietati p on lm.Cod=p.Cod where p.tip='LM' and left(cod_proprietate,4) in ('nume','func') and Valoare<>''
		and @lmutiliz like rtrim(lm.Cod)+'%' order by lm.Nivel desc, lm.Cod desc
		/**	se cauta locul de munca avand cel mai mic nivel care sa includa @LMUtiliz si sa aiba unitate*/
	declare @primLMcuUnitate varchar(20)
	select top 1 @primLMcuUnitate=lm.Cod from lm inner join proprietati p on lm.Cod=p.Cod where p.tip='LM' and cod_proprietate='UNITATE' and Valoare<>''
		and @lmutiliz like rtrim(lm.Cod)+'%' order by lm.Nivel desc, lm.Cod desc

	insert into @parrep(id,val_alfanumerica, parametru, val_numerica)
	select 1 as id,val_alfanumerica as valoare, parametru, 0 as val_numerica from par 
		where @primLMcuUnitate is null and tip_parametru='GE' and parametru='NUME' 
	union all
	select 1 as id,p.valoare, 'NUME', 0 as val_numerica from proprietati p 
		where @primLMcuUnitate is not null and tip='LM' and cod_proprietate='UNITATE' and cod=@primLMcuUnitate 
	union all
	select 3 as id, val_alfanumerica as valoare, parametru, convert(int,SUBSTRING(Parametru,5,1)) as val_numerica from par 
		where @primLMcuSemnaturi is null and tip_parametru='PS' and substring(parametru,1,4) in ('func','nume') and LEN(parametru)=5 and isnumeric(SUBSTRING(Parametru,5,1))>0 
	union all
	select 3 as id, p.valoare, p.cod_proprietate as parametru, SUBSTRING(cod_proprietate,5,3) as val_numerica from proprietati p 
		where @primLMcuSemnaturi is not null and tip='LM' and cod_proprietate like 'NUME%' and cod=@primLMcuSemnaturi and p.Valoare<>'' 
	union all
	select 3 as id, p.valoare, p.cod_proprietate as parametru, SUBSTRING(cod_proprietate,5,3) as val_numerica from proprietati p 
		where @primLMcuSemnaturi is not null and tip='LM' and cod_proprietate like 'FUNC%' and cod=@primLMcuSemnaturi and p.Valoare<>'' 
	union all
--	returnare date sucursala/filiala pentru registru electronic
	select 100 as id, p.valoare, p.cod_proprietate as parametru, 0 as val_numerica from proprietati p 
				where @primLMcuUnitate is not null and tip='LM' and cod_proprietate like 'ADRESA%' and cod=@primLMcuUnitate and p.Valoare<>'' union all
	select 100 as id, p.valoare, p.cod_proprietate as parametru, 0 as val_numerica from proprietati p 
				where @primLMcuUnitate is not null and tip='LM' and cod_proprietate='EMAIL' and cod=@primLMcuUnitate and p.Valoare<>'' union all
	select 100 as id, p.valoare, p.cod_proprietate as parametru, 0 as val_numerica from proprietati p 
				where @primLMcuUnitate is not null and tip='LM' and cod_proprietate='TELFAX' and cod=@primLMcuUnitate and p.Valoare<>'' union all
	select 100 as id, p.valoare, p.cod_proprietate as parametru, 0 as val_numerica from proprietati p 
				where @primLMcuUnitate is not null and tip='LM' and cod_proprietate='REPRREGITM' and cod=@primLMcuUnitate and p.Valoare<>'' union all
	select 100 as id, p.valoare, p.cod_proprietate as parametru, 0 as val_numerica from proprietati p 
				where @primLMcuUnitate is not null and tip='LM' and cod_proprietate='CODFISCAL' and cod=@primLMcuUnitate and p.Valoare<>'' union all
	select 100 as id, p.valoare, p.cod_proprietate as parametru, 0 as val_numerica from proprietati p 
				where @primLMcuUnitate is not null and tip='LM' and cod_proprietate='TIPSOCIETATE' and cod=@primLMcuUnitate and p.Valoare<>'' union all
	select 100 as id, p.valoare, p.cod_proprietate as parametru, 0 as val_numerica from proprietati p 
				where @primLMcuUnitate is not null and tip='LM' and cod_proprietate='CODSIRUTA' and cod=@primLMcuUnitate and p.Valoare<>''

	--if exists (select 1 from par where tip_parametru='GE' and parametru='FDIRGEN') -- setarea de baza
	--begin
	--	update @parrep set val_alfanumerica=(select val_alfanumerica from par where tip_parametru='GE' and parametru='FDIRGEN')	where parametru='FUNC1'
	----if exists (select 1 from par where tip_parametru='GE' and parametru='DIRGEN')
	--	update @parrep set val_alfanumerica=(select val_alfanumerica from par where tip_parametru='GE' and parametru='DIRGEN') where parametru='NUME1'
	----if exists (select 1 from par where tip_parametru='GE' and parametru='FDIREC')
	--	update @parrep set val_alfanumerica=(select val_alfanumerica from par where tip_parametru='GE' and parametru='FDIREC')	where parametru='FUNC2'
	----if exists (select 1 from par where tip_parametru='GE' and parametru='DIREC')
	--	update @parrep set val_alfanumerica=(select val_alfanumerica from par where tip_parametru='GE' and parametru='DIREC') where parametru='NUME2'
	--end	
--	inserez o pozitie cu FUNC1, NUME1 necompletate daca nu au fost configurate semnaturile 
--	altfel da eroare la rapoartele web (cauza este o conditie de vizibilitate) pe bazele de date unde nu sunt configurate semnaturile
	if not exists (select * from @parrep where parametru between 'NUME1' and 'NUME5' or parametru between 'FUNC1' and 'FUNC5')
		insert into @parrep(id, val_alfanumerica, parametru, val_numerica)
		select 3 as id, '' as valoare, 'FUNC1', 1 as val_numerica union all
		select 3 as id, '' as valoare, 'NUME1', 1 as val_numerica 

	return
end
