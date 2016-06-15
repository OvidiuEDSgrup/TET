--***
create procedure wScriuElemTipuri @sesiune varchar(50), @parXML xml
AS
declare @eroare varchar(1000)
set @eroare=''
begin try
/**	validare utilizator	*/
		declare @userASiS varchar(50)
		exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
/**	sectiunea de citire parametri	*/
declare @Tip_masina varchar(20),
		@Element varchar(20),	@o_Element varchar(20),
		@parinte varchar(20),
		@Mod_calcul varchar(1),
		@Formula varchar(2000),
		@Valoare decimal(20,2),
		@Ord_macheta smallint,
		@Ord_raport smallint,
		@Cu_totaluri bit,
		@Grupa varchar(20),
		@update int
select @Tip_masina=@parXML.value('(row/@cod)[1]','varchar(20)'),
		@Element=@parXML.value('(row/row/@element)[1]','varchar(20)'),
		@parinte=@parXML.value('(row/row/@parinte)[1]','varchar(20)'),
		@o_Element=@parXML.value('(row/row/@o_element)[1]','varchar(20)'),
		@Mod_calcul=isnull(@parXML.value('(row/row/@mod_calcul)[1]','varchar(1)'),'O'),
		@Formula=isnull(@parXML.value('(row/row/@formula)[1]','varchar(2000)'),''),
		@Valoare=isnull(@parXML.value('(row/row/@valoare)[1]','decimal(20,2)'),0),
		@Ord_macheta=isnull(@parXML.value('(row/row/@ord_macheta)[1]','smallint'),0),
		@Ord_raport=isnull(@parXML.value('(row/row/@ord_raport)[1]','smallint'),0),
		@Cu_totaluri=isnull(@parXML.value('(row/row/@cu_totaluri)[1]','bit'),0),
		@Grupa=isnull(@parXML.value('(row/row/@grupa)[1]','varchar(20)'),''),
		@update=isnull(@parXML.value('(row/@update)[1]','int'),0)
		/*	--tst
		select @Tip_masina,
				@Element,
				@Mod_calcul,
				@Formula,
				@Valoare,
				@Ord_macheta,
				@Ord_raport,
				@Cu_totaluri,
				@Grupa
		--	*/
/**	sectiunea in care se verifica validitate datelor si se executa modificarile	*/
	if (@parinte=@Element) raiserror('Nu este permisa alegerea aceluiasi element ca parinte al sau!',16,1)
	if (@parinte<>'') and not exists (select 1 from elemente e where e.Cod=@parinte)
		raiserror('Nu s-a definit elementul ales ca parinte!',16,1)
if (@update=1)
begin
	if (@Element<>@o_Element) raiserror('Nu este permisa schimbarea elementului la modificare!',16,1)
	update e set	--e.Mod_calcul=@Mod_calcul, e.Formula=@Formula, 
					e.Valoare=@Valoare, e.Formula=@parinte
					--,e.Ord_macheta=@Ord_macheta, e.Ord_raport=@Ord_raport, e.Cu_totaluri=@Cu_totaluri, e.Grupa=@Grupa
	from elemtipm e
		where e.Tip_masina=@Tip_masina and e.Element=@o_Element

end
else
begin
	if exists (select 1 from elemtipm e where e.Tip_masina=@Tip_masina and e.Element=@Element)
		raiserror('Elementul a fost operat deja pe acest tip de masina!',16,1)
	if (@Tip_masina is null) raiserror('Nu s-a identificat tipul caruia i se asociaza elementul!',16,1)
	if (isnull(@Element,'')='') raiserror('Nu s-a identificat elementul!',16,1)
	if (@Mod_calcul is null) raiserror('Nu s-a identificat modul elementului (Calcul/Operare)!',16,1)
	insert into elemtipm(Tip_masina ,Element ,Mod_calcul ,Formula ,Valoare ,Ord_macheta ,Ord_raport ,Cu_totaluri ,Grupa)
	select @Tip_masina ,@Element ,@Mod_calcul ,@parinte, @Valoare ,@Ord_macheta ,@Ord_raport ,@Cu_totaluri ,@Grupa
end
end try
begin catch
	set @eroare='wScriuElemTipuri:'+
		char(10)+rtrim(ERROR_MESSAGE())
end catch

if @eroare<>''
	raiserror(@eroare,16,1)
