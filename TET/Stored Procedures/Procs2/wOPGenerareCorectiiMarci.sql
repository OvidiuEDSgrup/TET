--***
Create procedure wOPGenerareCorectiiMarci @sesiune varchar(50), @parXML xml
as

declare @tip varchar(2), @sterg_corectii_ant int, @tip_corectie varchar(2), @den_corectie varchar(30), @data_corectie datetime, 
@lm varchar(9), @denlm varchar(30), @suma_corectie float, @procent_corectie float, @sex int, 
@userASiS varchar(20), @lunainch int, @anulinch int, @datainch datetime, @nrLMFiltru int, @LMFiltru varchar(9)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenNCSalarii' 

set @tip = ISNULL(@parXML.value('(/parametri/@tip)[1]', 'varchar(2)'), '')
set @sterg_corectii_ant = ISNULL(@parXML.value('(/parametri/@stergcor)[1]', 'int'), '')
set @tip_corectie = ISNULL(@parXML.value('(/parametri/@tipcor)[1]', 'varchar(2)'), '')
set @data_corectie = ISNULL(@parXML.value('(/parametri/@datacor)[1]', 'datetime'), '')
set @suma_corectie = ISNULL(@parXML.value('(/parametri/@sumacor)[1]', 'float'), 0)
set @procent_corectie = ISNULL(@parXML.value('(/parametri/@procentcor)[1]', 'float'), 0)
set @sex = ISNULL(@parXML.value('(/parametri/@sex)[1]', 'int'), 0)

select @nrLMFiltru=count(1), @LMFiltru=isnull(min(Cod),'') from LMfiltrare where utilizator=@userASiS and cod in (select cod from lm where Nivel=1)
set @lm = ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(9)'), '')
set @lm=(case when dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru=1 and @lm='' then @LMFiltru else @lm end)
select @denlm=isnull(Denumire,'') from lm where cod=@lm

set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
if @lunainch not between 1 and 12 or @anulinch<=1901 
	set @datainch='01/01/1901'
else 
	set @datainch=dbo.eom(convert(datetime,str(@lunainch,2)+'/01/'+str(@anulinch,4)))

begin try  
	--BEGIN TRAN
	if @tip_corectie=''
		raiserror('Selectati un tip de corectie!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm=''
		raiserror('Filtrati un loc de de munca pentru generarea corectiilor!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm<>'' and @lm not in (select cod from LMfiltrare where utilizator=@userASiS)
		raiserror('Locul de munca filtrat nu se regaseste in lista de locuri de munca pe care aveti acces!' ,16,1)
	if @data_corectie<=@datainch
		raiserror('Luna pe care doriti sa generati corectii este inchisa!' ,16,1)

	delete corectii from corectii c
		left outer join personal p on p.Marca=c.Marca
	where @sterg_corectii_ant=1 and Data=@data_corectie 
		and (@lm is null or p.Loc_de_munca like RTRIM(@lm)+'%')	and (@sex=2 or convert(int,p.Sex)=@sex)
	
	insert into corectii (Data, Marca, Loc_de_munca, Tip_corectie_venit, Suma_corectie, Procent_corectie, Suma_neta)
	select @data_corectie, p.Marca, p.Loc_de_munca, @tip_corectie, (case when @tip='CT' then @Suma_corectie else 0 end), 
	@procent_corectie, (case when @tip='CN' then @Suma_corectie else 0 end)
	from personal p
	where Loc_ramas_vacant=0 and (@lm is null or p.Loc_de_munca like RTRIM(@lm)+'%')
		and (@sex=2 or convert(int,p.Sex)=@sex)
		and not exists (select 1 from corectii c where c.Data=@data_corectie and c.Marca=p.Marca and c.Loc_de_munca=p.Loc_de_munca and c.Tip_corectie_venit=@tip_corectie)

	select @den_corectie=denumire from tipcor where tip_corectie_venit=@tip_corectie
	select 'S-au generat corectii pe marci, corectia '+RTRIM(@den_corectie)+' cu data '+convert(char(10),@data_corectie,103)+
	(case when @lm<>'' then ', pt. locul de munca '+rtrim(@denlm) else '' end)+'!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
	--COMMIT TRAN
end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wOPGenerareCorectiiMarci) '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
