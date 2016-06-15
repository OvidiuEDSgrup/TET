--***
create procedure wScriuPozD205 (@sesiune varchar(250), @parXML xml)
as

if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozD205SP')
begin
	declare @returnValue int
	exec @returnValue=wScriuPozD205SP @sesiune, @parXML output
	return @returnValue
end

begin try
	declare @userASiS char(10), @mesaj varchar(80), @update bit, @an int, @lm varchar(9), @LMFiltru varchar(9),
	@tip_venit char(2), @tip_impozit char(2), @marca varchar(6), @cnp varchar(13), @nume varchar(100), @tip_functie char(1),
	@venit_brut float, @deduceri_personale float, @deduceri_alte float, @baza_impozit float, @impozit float, 
	@o_tip_venit varchar(2), @o_tip_impozit char(2), @o_marca varchar(6), @o_cnp varchar(13), @o_tip_functie varchar(1), @docXMLIaPozD205 xml
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	
	select  @an=ISNULL(@parXML.value('(/row/@an)[1]','int'),''),
		@lm=isnull(@parXML.value('(/row/row/@lm)[1]','varchar(9)'),''),
		@tip_venit=isnull(@parXML.value('(/row/row/@tipvenit)[1]','varchar(2)'),''),
		@tip_impozit=isnull(@parXML.value('(/row/row/@tipimpozit)[1]','char(1)'),''),
		@marca=isnull(@parXML.value('(/row/row/@marca)[1]','varchar(6)'),''),
		@cnp=isnull(@parXML.value('(/row/row/@cnp)[1]','varchar(13)'),''),
		@nume=ISNULL(@parXML.value('(/row/row/@nume)[1]','varchar(100)'),''),
		@tip_functie=ISNULL(@parXML.value('(/row/row/@tipfunctie)[1]','varchar(1)'),''),
		@venit_brut=isnull(@parXML.value('(/row/row/@venitbrut)[1]','decimal(10)'),0),
		@deduceri_personale=isnull(@parXML.value('(/row/row/@dedpers)[1]','decimal(10)'),0),
		@deduceri_alte=isnull(@parXML.value('(/row/row/@dedalte)[1]','decimal(10)'),0),
		@baza_impozit=isnull(@parXML.value('(/row/row/@bazaimpozit)[1]','decimal(10)'),0),
		@impozit=isnull(@parXML.value('(/row/row/@impozit)[1]','decimal(10)'),0),
		@update=isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@o_tip_venit=isnull(@parXML.value('(/row/row/@o_tipvenit)[1]','varchar(2)'),''),
		@o_tip_impozit=isnull(@parXML.value('(/row/row/@o_tipimpozit)[1]','char(1)'),''),
		@o_marca=isnull(@parXML.value('(/row/row/@o_marca)[1]','varchar(6)'),''),
		@o_cnp=isnull(@parXML.value('(/row/row/@o_cnp)[1]','varchar(13)'),''),
		@o_tip_functie=isnull(@parXML.value('(/row/row/@o_tipfunctie)[1]','varchar(1)'),'')

--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		select @LMFiltru=isnull(min(Cod),'') from LMfiltrare where utilizator=@userASiS
	if @update=0 and isnull(@LMFiltru,'')<>''
		set @lm=@LMFiltru

	if @marca<>'' and not exists (select 1 from personal where Marca=@marca)
		raiserror('Marca inexistenta!',11,1)
	if @marca='' and @cnp='' 
		raiserror('Trebuie completat marca sau CNP!',11,1)
	if @marca='' and @Nume='' 
		raiserror('Nume necompletat!',11,1)
	if @marca<>'' and @cnp<>'' 
		raiserror('Trebuie completat marca sau CNP/nume!',11,1)
		
	if @update=0 -- adaugare
	begin
		insert into DateD205 (an,loc_de_munca,tip_venit,tip_impozit,marca,cnp,nume,tip_functie,venit_brut,Deduceri_personale,Deduceri_alte,Baza_impozit,Impozit)
		values (@an,@lm,@tip_venit,@tip_impozit,@marca,@cnp,@nume,@tip_functie,@venit_brut,@deduceri_personale,@deduceri_alte,@baza_impozit,@impozit)
	end
	else --modificare
	begin 
		update DateD205 set Tip_venit=@tip_venit, Tip_impozit=@tip_impozit,
			marca=@marca, cnp=@cnp, nume=@nume, tip_functie=@tip_functie, 
			Venit_brut=@venit_brut, Deduceri_personale=@deduceri_personale, Deduceri_alte=@deduceri_alte, Baza_impozit=@baza_impozit, impozit=@impozit
		where An=@an and Loc_de_munca=@lm and Tip_venit=@o_tip_venit and Tip_impozit=@o_tip_impozit and marca=@o_marca 
			and cnp=@o_cnp and Tip_functie=@o_tip_functie
	end
	
	set @docXMLIaPozD205='<row an="'+convert(char(4),@an)+'"/>'
	exec wIaPozD205 @sesiune=@sesiune, @parXML=@docXMLIaPozD205

end try
begin catch
	set @mesaj=' (wScriuPozD205): '+ERROR_MESSAGE()
	raiserror(@mesaj,11,1)
end catch
