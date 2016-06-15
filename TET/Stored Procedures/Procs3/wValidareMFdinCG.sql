--***  
create procedure wValidareMFdinCG @sesiune varchar(50), @parXML xml
as                  

begin try
-- validari pentru transferuri in CG cu gestiune primitoare/predatoare tip I (Imobilizari) 
declare @subunitate varchar(9), @tip varchar(2), @subtip varchar(2), @numar varchar(20), @data datetime, @numarpozitie int, @nrinv varchar(25), @ptupdate int, @stergMF int

select @tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'), isnull(@parXML.value('(/parametri/@tip)[1]','varchar(2)'),'')), 
	@subtip=isnull(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'), isnull(@parXML.value('(/parametri/@subtip)[1]','varchar(2)'),'')),
	@numar=isnull(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), isnull(@parXML.value('(/parametri/@numar)[1]','varchar(20)'),'')),
	@data=isnull(@parXML.value('(/row/@data)[1]', 'datetime'), isnull(@parXML.value('(/parametri/@data)[1]','datetime'),'1901-01-01')),
	@numarpozitie=@parXML.value('(/row/row/@numarpozitie)[1]', 'int'),
	@ptupdate=isnull(@parXML.value('(/row/row/@update)[1]','int'), 0),
	@stergMF=isnull(@parXML.value('(/row/row/@stergMF)[1]','int'), 0)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

-- validari pentru intrari de mijloace fixe operate ca RM 
if @tip='RM' and @parXML is not null
begin
	declare @denmf varchar(80), @codcl varchar(13), @contam varchar(40), @durata int
	select @denmf=isnull(@parXML.value('(/row/row/detalii/row/@denmf)[1]', 'char(80)') ,''),
		@codcl=isnull(@parXML.value('(/row/row/detalii/row/@codcl)[1]', 'char(13)') ,''),
		@contam=isnull(@parXML.value('(/row/row/detalii/row/@contam)[1]', 'char(40)') ,''),
		@nrinv=isnull(@parXML.value('(/row/row/@codintrare)[1]', 'varchar(25)'),''),
		@durata=isnull(@parXML.value('(/row/row/detalii/row/@durata)[1]', 'int') ,0)

	IF OBJECT_ID('tempdb..#nrinv') IS NOT NULL drop table #nrinv
	select cod_intrare as nrinv 
	into #nrinv
	from pozdoc p
		inner join gestiuni g on g.Subunitate=p.Subunitate and g.Cod_gestiune=p.Gestiune and g.Tip_gestiune='I'
	where p.subunitate=@subunitate and Tip=@tip and Numar=@numar and Data=@data and subtip='MF'
		and (@subtip in ('RP','DV') or @numarpozitie is null or Numar_pozitie=@numarpozitie)
	if @subtip='MF' and @ptupdate=0
		insert into #nrinv values (@nrinv)

--	validez daca exista deja un mijloc fix cu acest numar de inventar (cod intrare) pe care s-a calculat amortizarea
	if exists (select 1 from mfix inner join #nrinv on Numar_de_inventar=nrinv where subunitate=@subunitate)
		and exists (select 1 from fisamf inner join #nrinv on Numar_de_inventar=nrinv where subunitate=@subunitate and Valoare_amortizata<>0)
		and exists (select 1 from mismf inner join #nrinv on Numar_de_inventar=nrinv where subunitate=@subunitate and Data_miscarii=@data and Tip_miscare='IAF')
		--tratat sa se poata permite stergerea intrarii unui mijloc fix
		and @stergMF=0
	begin
		raiserror('Nr. de inventar de pe acest document exista deja si s-a inceput amortizarea!',11,1)
		return
	end
	IF OBJECT_ID('tempdb..#nrinv') IS NOT NULL drop table #nrinv

	if @subtip='MF'
	begin
--	validare denumire mijloc fix
		if @denmf=''
		begin
			raiserror('Denumire mijloc fix necompletata!',11,1)
			return
		end
--	validare cod de clasificare
		if @codcl=''
		begin
			raiserror('Cod de clasificare necompletat!',11,1)
			return
		end
--	validare cont de amortizare
		if not exists (select 1 from conturi where cont=@contam and are_analitice=0)
		begin
			raiserror('Cont amortizare inexistent sau cu analitice!',11,1)
			return
		end
--	validare durata de amortizare (exprimata in ani)
		if @durata=0 and 1=0
		begin
			raiserror('Durata amortizare mijloc fix necompletata!',11,1)
			return
		end
	end
end

-- transferuri spre/dinspre gestiune de tip I (imobilizari)
if @tip='TE'
begin
	declare @gestiune varchar(13), @gestiunePrim varchar(40), @eroare varchar(2000)

	select @data=isnull(@parXML.value('(/row/@data)[1]','datetime'),''),
		@gestiune=isnull(@parXML.value('(/row/row/@gestiune)[1]','varchar(13)'),isnull(@parXML.value('(/row/@gestiune)[1]','varchar(13)'),'')),
		@gestiunePrim=isnull(@parXML.value('(/row/row/@gestprim)[1]','varchar(40)'),isnull(@parXML.value('(/row/@gestprim)[1]','varchar(40)'),'')),
		@nrinv=rtrim(isnull(@parXML.value('(/row/linie/@codiprimitor)[1]', 'varchar(25)'), @parXML.value('(/row/row/@codiprimitor)[1]', 'varchar(25)')))

--	subtip=TE (cu gestiune primitoare tip I) validez daca exista deja un mijloc fix cu acest numar de inventar (cod intrare)
	if @subtip='TE' and isnull((select tip_gestiune from gestiuni where Subunitate=@subunitate and Cod_gestiune=@gestiunePrim),'')='I'
		and exists (select 1 from mfix where subunitate=@subunitate and Numar_de_inventar=@nrinv)
			and exists (select 1 from fisamf where subunitate=@subunitate and Numar_de_inventar=@nrinv and Valoare_amortizata<>0)
			and exists (select 1 from mismf where subunitate=@subunitate and Numar_de_inventar=@nrinv and Data_miscarii=@data and Tip_miscare='IAL')
	begin
		raiserror('Acest nr. de inventar exista deja si s-a inceput amortizarea!',11,1)
		return
	end

--	subtip=TR (transfer retur cu gestiune predatoare tip I) completez in parXML codul de nomenclator (=cod din mfix.detalii completat la momentul TE initial) si codiprimitor=codintrare
	if @subtip='TR' and isnull((select tip_gestiune from gestiuni where Subunitate=@subunitate and Cod_gestiune=@gestiune),'')='I'
	begin
		set @nrinv=isnull(@parXML.value('(/row/row/@codintrare)[1]', 'varchar(25)'),'')

--	validare daca nu s-a efectuat calcul amortizare pe luna transferului
		if not exists (select 1 from fisamf f where f.Subunitate=@subunitate and f.Numar_de_inventar=@nrinv and Data_lunii_operatiei=dbo.EOM(@data) and f.Felul_operatiei='1')
		begin
			declare @luna varchar(15), @mesajEroare varchar(max)
			set @luna=dbo.fDenumireLuna(@data)
			set @mesajEroare='Nu s-au efectuat calcule lunare in MF pentru luna '+rtrim(@luna)+' '+convert(char(4),year(@data))+'!'
			raiserror(@mesajEroare,16,1)			
		end
	end

end
end try

begin catch
	set @eroare=ERROR_MESSAGE()+' (wValidareMFdinCG)'
	if @eroare is not null raiserror(@eroare,16,1)
end catch
	
