--***
create procedure wIntrareNou @sesiune varchar(50), @parXML xml
as 
declare @comanda varchar(max), @proprietate varchar(100),	@utilizator varchar(20),@nume varchar(100),@GESTPV varchar(50),
		@parola varchar(255), @msgEroare varchar(max), @aplicatie varchar(50), @versiuneApp varchar(50), @versiuneMinima varchar(50),
		@serverrap varchar(200), @raspuns varchar(max), @mesajEroare varchar(4000), 
		@versiuneScripturiRia varchar(200), @versiuneScripturiASiS varchar(200), @versiuneSQL varchar(200)

set nocount on
begin try

select	@aplicatie = @parXML.value('(/row/@aplicatie)[1]','varchar(50)'),
		@versiuneApp = @parXML.value('(/row/@versiune)[1]','varchar(50)'),
		@versiuneScripturiRia=''
	
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

select @nume=rtrim(Nume),@parola=rtrim(info) from utilizatori where ID=@utilizator

select @versiuneScripturiASiS=rtrim(Val_alfanumerica) from par where Tip_parametru='AS' and Parametru='VERSIUNE'
select @versiuneScripturiRia=rtrim(Val_alfanumerica) from par where Tip_parametru='AR' and Parametru='VERSIUNE'

select @serverrap=rtrim(Val_alfanumerica) from par where Tip_parametru='AR' and Parametru='REPSRVADR'
set @serverrap=@serverrap+(case when RIGHT(@serverrap,1)!='/' then '/' else '' end)	/**	Adresa srv de Reporting configurata pt ria*/
if @serverrap is null 
	set @serverrap=''

SELECT @versiuneSQL=convert(varchar(100),SERVERPROPERTY('productversion'))

if @utilizator is null 
begin
	if @sesiune=''
		set @msgEroare='Nu pot identifica utilizatorul pentru sesiunea '+@sesiune
	else
		set @msgEroare = 'Utilizatorul windows('+SUSER_NAME() + ') nu are atasat utilizator de ASiS!'
	raiserror(@msgEroare, 11, 1)
	return -1
end

declare @atributeTable table (nume varchar (50), valoare varchar(200))

declare @areRap int
if exists(select * from webConfigRapoarte w inner join dbo.fIaGrupeUtilizator(@utilizator) f on w.utilizator=f.grupa) or dbo.wfAreSuperDrept(@utilizator)=1
	set @areRap=1
else 
	set @areRap=0

declare @areTB int
if exists(select * from webConfigMeniuUtiliz wut,webConfigMeniu wm, dbo.fIaGrupeUtilizator(@utilizator) f
					where wm.meniu=wut.meniu and wut.IdUtilizator=f.grupa and TipMacheta='G')
		and exists (select 1 from sysobjects where name='wIaCategoriiTB')
	set @areTB=1
else 
	set @areTB=0


insert into @atributeTable(nume, valoare)
select 'utilizator', @utilizator 
union all
select 'nume', @nume
union all
select 'parola' , @parola
union all
select 'serverrap', @serverrap  
union all
select 'arerap', ltrim(str(@arerap)) 
union all
select 'aretb', ltrim(str(@aretb)) 
union all
select 'versiunescripturiasis', @versiuneScripturiASiS
union all
select 'versiunescripturiria', @versiuneScripturiRia
union all
select 'versiuneserversql', @versiuneSQL

insert into @atributeTable(nume, valoare)
select distinct p.Cod_proprietate, MAX(p.Valoare)
from proprietati p 
inner join tipproprietati tp on p.tip=tp.Tip and p.Cod_proprietate=tp.Cod_proprietate
where p.tip='UTILIZATOR' and p.Cod=@utilizator and p.cod_proprietate!='CATEGPRET' and p.Valoare <> ''
group by p.Cod_proprietate

exec intrareUser @sesiune,@parXML

/* specific PV: validare versiune si atasare proprietati atasate gestiunii userului. */
if @aplicatie='PV'
begin 
	set @versiuneMinima=(select rtrim(val_alfanumerica) from par where Tip_parametru='AR' and Parametru='PV')
	if @versiuneApp<@versiuneMinima
	begin
		set @mesajEroare='Va rugam actualizati aplicatia. Versiunea curenta a aplicatiei('+@versiuneApp+') nu functioneaza corect cu procedurile ASiSria instalate pe server. '+CHAR(10)+
			'Versiunea minima este '+@versiuneMinima+'.'
		raiserror(@mesajEroare,11,1)
	end
	
	set @GESTPV=rtrim(dbo.wfProprietateUtilizator('GESTPV',@utilizator ))
	if len( @GESTPV ) > 0
	begin
		-- inserez atributele asociate gestiunii GESTPV
		insert into @atributeTable(nume, valoare)
		select Cod_proprietate, rtrim(max(valoare)) from proprietati p
		where 
			tip='GESTIUNE' and cod=@GESTPV 
			and not exists (select 1 from @atributeTable at where at.nume=p.Cod_proprietate)
			and p.Valoare<>''
		group by Cod_proprietate
		
	end
	else
	begin
		set @mesajEroare='Utilizatorul logat('+isnull(@utilizator,'')+') nu are configurata proprietatea GESTPV. Fara aceasta proprietate nu se poate vinde din aplicatia PVria.'
		raiserror(@mesajEroare,11,1)
	end
	
	-- validare lista gestiuni
	declare @listaGestiuni varchar(300), @existaGestiune bit
	exec luare_date_par 'PG',@GESTPV,0,0,@listaGestiuni output
	if charindex(';'+RTrim(@GESTPV)+';',';'+RTrim(@listaGestiuni)+';')=0
		set @listaGestiuni=RTrim(@GESTPV)+';'+RTrim(@listaGestiuni)
	declare @gestiuni table (gestiune varchar(20) primary key)
	insert @gestiuni(gestiune)
		select distinct item
		from dbo.Split(@listaGestiuni,';')
		where item<>''
	
	delete g
		from @gestiuni g
		inner join proprietati p on p.Cod_proprietate='GESTIUNE' and p.Tip='UTILIZATOR' and p.Cod=@utilizator and g.gestiune=p.Valoare
	
	if exists ( select * from @gestiuni) and isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod_proprietate='GESTIUNE' and cod=@utilizator),'')!=''
	begin
		set @mesajEroare=null
		select @mesajEroare=ISNULL(@mesajEroare+', ','')+gestiune
		 from @gestiuni
		
		set @mesajEroare='Gestiunile '+ @mesajEroare +' sunt configurate ca gestiuni de transfer pentru gestiunea '+@GESTPV+ ', dar utilizatorul '+@utilizator+
			' nu are drept de acces pe ele! Adaugati gestiunile in lista gestiunilor atasate utilizatorului.'
		raiserror(@mesajEroare,11,1)
	end
	--Pentru legare utilizator de adresa MAC
	declare @maxmac int
	select @maxmac=convert(int,Valoare) from proprietati where tip='UTILIZATOR' and cod_proprietate='MAXMAC' and cod=@utilizator
	if @maxmac is null
		set @maxmac=0
	
	if @maxmac>0 -- Are aceasta proprietate
	begin
		declare @nrmacurifolosite int,@macprimit varchar(255)
		select @nrmacurifolosite=count(*) from proprietati where tip='UTILIZATOR' and cod_proprietate='ADRMAC' and cod=@utilizator
		
		select	@macprimit= @parXML.value('(/row/@adrmac)[1]','varchar(50)')
		--Daca exista inseamna ca e ok
		--Daca nu exista verificam daca numarul de macuri este mai mic decat cel care trebuie si inseram
		if not exists(select 1 from proprietati where tip='UTILIZATOR' and cod_proprietate='ADRMAC' and cod=@utilizator and valoare=@macprimit)
		begin
			if (@nrmacurifolosite<@maxmac)
				insert into proprietati(tip,cod,cod_proprietate,valoare,valoare_tupla)
					values ('UTILIZATOR',@utilizator,'ADRMAC',@macprimit,'')
			else
				raiserror('Nu aveti acces pe acest calculator!Rezolvati proprietatea ADRMAC!',16,1)
		end
	end
	
	declare @dataPVria datetime
	set @dataPVria=@parXML.value('(/row/@datasistem)[1]','datetime')
	if @dataPVria <> convert(datetime,convert(char(10),getdate(),101),101) and @dataPVria is not null /* e null daca e PVria vechi. */
	begin
		set @mesajEroare='Data configurata pe statia de lucru este diferita de data serverului! Va rugam sa corectati data sistemului.'
		raiserror(@mesajEroare,11,1)
	
	end

end

if @aplicatie='AM' /* aplicatie ASiSmobile - validare versiune */
begin 
	if exists (select * from sysobjects where name ='wIntrareMobile')
		exec wIntrareMobile @sesiune=@sesiune, @parXML=@parXML
end

/** Se verifica existenta unui SP2 complementar unde se pot face diverse lucruri: exemplu-> prefiltrare LM **/
if exists (select 1 from sysobjects where [type]='P' and [name]='wIntrareNouSP2')    
		exec wIntrareNouSP2 @sesiune=@sesiune,@parXML=@parXML

/* acest select ar trebui modificat: generarea atributelor trebuie facuta cumva asa, dar inserarea 
valorilor ar trebui sa se faca prin @parXML.modify, cu replace(replace merge si cu atribute dinamice, dar insert attribute nu permite aceasta). */
set @raspuns='<row '
SELECT @raspuns=@raspuns+ rtrim(nume) + '="' +  (select rtrim(valoare) as [text()] for xml path('')) + '" '
FROM @atributeTable
set @raspuns=@raspuns+'/>'

select convert(xml,@raspuns)

end try
begin catch 
	declare @errormessage varchar(2000), @errorseverity varchar(2000), @errorstate varchar(500)
	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )

end catch
