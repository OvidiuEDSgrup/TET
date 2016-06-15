--***
create function fDenumiriRapPS (@sesiune varchar(50), @parXML xml)
returns @denumiri table (parametru varchar(50), valoare varchar(2000))
as 
begin

declare @datajos datetime, @marca varchar(50), @functie varchar(50), @benret varchar(50), @subtipret varchar(50), @tipcorectie varchar(50),
		@subtipcor varchar(50), @marcazilier varchar(50), @codfiscPS varchar(50), 
		--	ore suplimentare
		@denosupl1 varchar(50), @denosupl2 varchar(50), @denosupl3 varchar(50), @denosupl4 varchar(50),
		--	nume si functie pt. persoana care intocmeste adeverinte de salarizare (reprezentant personal)
		@nreprpers varchar(50), @freprpers varchar(50)


select @datajos=@parXML.value('(row/@datajos)[1]','datetime'),
		@marca=@parXML.value('(row/@marca)[1]','varchar(50)'),
		@functie=@parXML.value('(row/@functie)[1]','varchar(50)'),
		@benret=@parXML.value('(row/@benret)[1]','varchar(50)'),
		@subtipret=@parXML.value('(row/@subtipret)[1]','varchar(50)'),
		@tipcorectie=@parXML.value('(row/@tipcorectie)[1]','varchar(50)'),
		@subtipcor=@parXML.value('(row/@subtipcor)[1]','varchar(50)'),
		@marcazilier=@parXML.value('(row/@marcazilier)[1]','varchar(50)'),
		@codfiscPS=(case when @parXML.value('(row/@codfiscps)[1]','varchar(50)') is not null then 'CODFISC' else null end),
		@denosupl1=(case when @parXML.value('(row/@osupl1)[1]','varchar(50)') is not null then 'OSUPL1' else null end),
		@denosupl2=(case when @parXML.value('(row/@osupl2)[1]','varchar(50)') is not null then 'OSUPL2' else null end),
		@denosupl3=(case when @parXML.value('(row/@osupl3)[1]','varchar(50)') is not null then 'OSUPL3' else null end),
		@denosupl4=(case when @parXML.value('(row/@osupl4)[1]','varchar(50)') is not null then 'OSUPL4' else null end),
--	nume si functie pt. persoana care intocmeste declaratiile de TVA
		@nreprpers=(case when @parXML.value('(row/@nreprpers)[1]','varchar(50)') is not null then 'NREPRPERS' else null end),
		@freprpers=(case when @parXML.value('(row/@freprpers)[1]','varchar(50)') is not null then 'FREPRPERS' else null end)


insert into @denumiri(parametru,valoare)
	select '@'+lower(rtrim(parametru)) as parametru,rtrim(val_alfanumerica) as valoare
		from par where tip_parametru='PS' and parametru in (@denosupl1,@denosupl2,@denosupl3,@denosupl4,@nreprpers,@freprpers)
	
insert into @denumiri(parametru,valoare)
	select '@marca', rtrim(isnull((select max(i.Nume) from istpers i where i.Marca=@marca
			and (@datajos is null or month(i.Data)=month(@datajos) and year(i.Data)=year(@datajos))),'<nu exista>')) 
		where @marca is not null union all
	select '@functie', rtrim(isnull((select max(f.Denumire) from functii f where f.Cod_functie=@functie),'<nu exista>')) 
		where @functie is not null union all
	select '@benret', rtrim(isnull((select max(b.Denumire_beneficiar) from benret b where b.Cod_beneficiar=@benret),'<nu exista>')) 
		where @benret is not null union all
	select '@subtipret', rtrim(isnull((select max(t.Denumire) from tipret t where t.Subtip=@subtipret),'<nu exista>')) 
		where @subtipret is not null union all
	select '@tipcorectie', rtrim(isnull((select max(t.Denumire) from tipcor t where t.Tip_corectie_venit=@tipcorectie),'<nu exista>')) 
		where @tipcorectie is not null union all
	select '@subtipcor', rtrim(isnull((select max(s.Denumire) from subtipcor s where s.Subtip=@subtipcor),'<nu exista>')) 
		where @subtipcor is not null union all
	select '@codfiscps', rtrim(isnull((select max(s.Denumire) from subtipcor s where s.Subtip=@subtipcor),'<nu exista>')) 
		where @subtipcor is not null union all
	select '@codfiscps' as parametru, rtrim(val_alfanumerica) as valoare
		from par where tip_parametru='PS' and parametru in (@codfiscPS) --union all
		--> s-ar putea ca tabela zilieri sa nu existe (la clientii care nu au rulat +tabelePS din directorul PS):
	if exists (select 1 from sysobjects o where o.type='U' and (o.name='zilieri'))
	insert into @denumiri(parametru,valoare)
	select '@marcazilier', rtrim(isnull((select max(z.Nume) from zilieri z where z.Marca=@marcazilier),'<nu exista>')) 
		where @marcazilier is not null 

return
end
