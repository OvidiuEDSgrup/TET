--***  
create procedure wPregatireMFdinCG @sesiune varchar(50), @parXML xml output
as                  

begin try
-- validari pentru transferuri in CG cu gestiune primitoare/predatoare tip I (Imobilizari) 
declare @tip varchar(2), @subtip varchar(2), @subunitate varchar(9), @numar varchar(20), @data datetime, @gestiune varchar(13), @cod varchar(25), @cantitate int, 
	@nrinv varchar(25), @contmf varchar(40), @cont_factura varchar(40), @eroare varchar(2000)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
--	momentan punem contul intr-o variabila, nu exista setare in MFplus
	set @cont_factura='404'

select @tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),''),
	@subtip=isnull(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'),''),
	@numar=isnull(@parXML.value('(/row/@numar)[1]','varchar(20)'),''),
	@data=isnull(@parXML.value('(/row/@data)[1]','datetime'),''),
	@gestiune=isnull(@parXML.value('(/row/row/@gestiune)[1]','varchar(13)'),isnull(@parXML.value('(/row/@gestiune)[1]','varchar(13)'),''))

if @tip='RM' and @subtip in ('MF','MM')
begin
	select @nrinv=@parXML.value('(/row/row/@codintrare)[1]', 'varchar(25)'), 
		@contmf=isnull(@parXML.value('(/row/row/@contstoc)[1]', 'varchar(40)'),''),
		@cantitate=@parXML.value('(/row/row/@cantitate)[1]', 'decimal(17, 5)')

--	sugerare cont factura
	if nullif(@parXML.value('(/row/@contfactura)[1]', 'varchar(40)'),'') is null
	begin
		if @parXML.value('(/row/row/@contfactura)[1]', 'varchar(40)') is null
			set @parXML.modify ('insert attribute contfactura {sql:variable("@cont_factura")} into (/row/row)[1]') 
		if @parXML.value('(/row/row/@contfactura)[1]', 'varchar(40)') = ''
			set @parXML.modify('replace value of (/row/row/@contfactura)[1] with sql:variable("@cont_factura")')
	end

	if @subtip='MM'
	begin
		if @parXML.value('(/row/row/@contcorespondent)[1]', 'varchar(40)') is null
			set @parXML.modify ('insert attribute contcorespondent {sql:variable("@cont_factura")} into (/row/row)[1]') 
		if @parXML.value('(/row/row/@contfactura)[1]', 'varchar(40)') = ''
			set @parXML.modify('replace value of (/row/row/@contcorespondent)[1] with sql:variable("@cont_factura")')

--	gestiunea se va lua tot timpul din fisamf la modificari de valoare (cea din antet poate fi si diferita de tip I, iar daca cea din pozitii difera de cea din fisaMF, ar trebui poate generat si un Transfer)
		set @gestiune=isnull((select top 1 gestiune from fisamf where subunitate=@subunitate and Numar_de_inventar=@nrinv 
			and Data_lunii_operatiei<=dbo.EOM(@data) and felul_operatiei='1' order by Data_lunii_operatiei desc),'')
		if @parXML.value('(/row/row/@gestiune)[1]', 'varchar(13)') is null
			set @parXML.modify ('insert attribute gestiune {sql:variable("@gestiune")} into (/row/row)[1]') 
		else
			set @parXML.modify('replace value of (/row/row/@gestiune)[1] with sql:variable("@gestiune")')

		if @contmf=''
		begin
			set @contmf=isnull((select top 1 cont_mijloc_fix from fisamf where subunitate=@subunitate and Numar_de_inventar=@nrinv 
				and Data_lunii_operatiei<=dbo.EOM(@data) and felul_operatiei='1' order by Data_lunii_operatiei desc),'')
			if @parXML.value('(/row/row/@contstoc)[1]', 'varchar(40)') is null
				set @parXML.modify ('insert attribute contstoc {sql:variable("@contmf")} into (/row/row)[1]') 
			if @parXML.value('(/row/row/@contstoc)[1]', 'varchar(40)') = ''
				set @parXML.modify('replace value of (/row/row/@contstoc)[1] with sql:variable("@contmf")')
		end
	end

--	sugerare cod 
	if @parXML.value('(/row/row/@cod)[1]', 'varchar(25)') is null
	begin
		set @cod='MIJLOC_FIX_MF'
		set @parXML.modify ('insert attribute cod {sql:variable("@cod")} into (/row/row)[1]')
	end

--	cantitate=1 daca nu este completata
	if @cantitate is null
	begin
		set @cantitate=1
		set @parXML.modify ('insert attribute cantitate {sql:variable("@cantitate")} into (/row/row)[1]') 
	end
end

if @tip='RM' and @subtip='MF'
begin
	declare @ValminMF float, @factura varchar(20), @codcl varchar(13), @tipam char(1), @categmf int, @durata int, @UltNrinv int, 
		@contam varchar(40), @cont281 char(40), @OptCont281 int, @Analitic21La281 int, @pvaluta float

--	parametrii 
	select @ValminMF=max((case when parametru='' then Val_numerica else 0 end)), 
		@Cont281=max((case when parametru='CA281' then rtrim(Val_alfanumerica) else '' end)), 
		@OptCont281=max((case when parametru='CA281' then Val_numerica else 0 end))
	from par where tip_parametru='MF' and parametru in ('VALOBINV','CA281')
	set @Analitic21La281=(case when @OptCont281=2 then 1 else 0 end)

	select @factura=@parXML.value('(/row/@factura)[1]', 'varchar(20)'),
		@cod=@parXML.value('(/row/row/@cod)[1]', 'varchar(25)'),
		@codcl=isnull(@parXML.value('(/row/row/detalii/row/@codcl)[1]', 'varchar(20)') ,''),
		@durata=isnull(@parXML.value('(/row/row/detalii/row/@durata)[1]', 'int'),0),
		@tipam=isnull(@parXML.value('(/row/row/detalii/row/@tipam)[1]', 'char(1)'),'2'),
		@contam=@parXML.value('(/row/row/detalii/row/@contam)[1]', 'varchar(40)')

--	completare sufix M la facturile de mijloace fixe daca pe acelasi document exista pozitii anterioare cu cont factura <>404
	if exists (select 1 from pozdoc where subunitate=@subunitate and Tip=@tip and Numar=@numar and Data=@data and Cont_factura<>@cont_factura) and right(rtrim(@factura),1)<>'M'
	begin
		set @factura=rtrim(@factura)+'M'
		if @parXML.value('(/row/row/@factura)[1]', 'varchar(20)') is null
			set @parXML.modify ('insert attribute factura {sql:variable("@factura")} into (/row/row)[1]') 
		if @parXML.value('(/row/row/@factura)[1]', 'varchar(20)') = ''
			set @parXML.modify('replace value of (/row/row/@factura)[1] with sql:variable("@factura")')
	end

--	este nevoie de categorie pentru stabilire cont mijloc fix
	set @categmf=convert(int,(case when left(@codcl,1)='2' then left(@codcl,1)+substring(@codcl,3,1) else left(@codcl,1) end))
--	determinare nr. de inventar functie de ultimul numar utilizat
	if isnull(@nrinv,'')=''
	begin
		if @UltNrinv is null
			set @UltNrinv=isnull(convert(int,dbo.iauParN('MF','ULTNRINV'))+1,1)

		while exists (select 1 from mfix where Numar_de_inventar=RTrim(LTrim(convert(char(13), @UltNrinv))))
			set @UltNrinv = @UltNrinv + 1
		set @nrinv=RTrim(LTrim(convert(char(13), @UltNrinv)))
		if @parXML.value('(/row/row/@codintrare)[1]', 'varchar(25)') is null
			set @parXML.modify ('insert attribute codintrare {sql:variable("@nrinv")} into (/row/row)[1]') 
		if @parXML.value('(/row/row/@codintrare)[1]', 'varchar(25)') = ''
			set @parXML.modify('replace value of (/row/row/@codintrare)[1] with sql:variable("@nrinv")')
	end
	if @UltNrinv is not null
		exec setare_par 'MF', 'ULTNRINV', null, null, @UltNrinv, null
--	terminat cu nr. de inventar 

--	durata de amortizare
	if @durata=0 select @durata=DUR_min from codclasif where Cod_de_clasificare=@codcl

--	formare cont mijloc fix
	if @contmf=''
	begin
		select @contmf=rtrim(val_alfanumerica) from par where tip_parametru='MF' and parametru='C212'+
			(case when Left(@codcl,1)='1' then '1' when Left(@codcl,1)='3' then '6' when Left(@codcl,1)='8' then '8' 
				when Left(@codcl,1)+substring (@codcl,3,1)='21' then '2' when Left (@codcl,1)+substring (@codcl,3,1)='22' then '3' 
				when Left (@codcl,1)+substring (@codcl,3,1)='23' then '4' when Left (@codcl,1)+substring (@codcl,3,1)='24' then '5' else '9' end)
				+(case when @pvaluta<@ValminMF then 'OB' else 'M' end)
				+(case when 1=1 then 'C' else 'A' end)

		if @parXML.value('(/row/row/@contstoc)[1]', 'varchar(40)') is null
			set @parXML.modify ('insert attribute contstoc {sql:variable("@contmf")} into (/row/row)[1]') 
		if @parXML.value('(/row/row/@contstoc)[1]', 'varchar(40)') = ''
			set @parXML.modify('replace value of (/row/row/@contstoc)[1] with sql:variable("@contmf")')
	end
--	formare cont amortizare mijloc fix
	if isnull(@contam,'')=''
	begin
		set @contam=(case when left(@contmf,3)='303' or @tipam='1' then '' when @categmf='8' then '2811'  when @categmf='7' then '2808' 
			else rtrim(@cont281)+(case when @Analitic21La281=1 then substring(@contmf,(case when len(rtrim(@contmf))=3 then 3 else 4 end),11) else '' end) end)

		if @parXML.value('(/row/row/detalii/row/@contam)[1]', 'varchar(40)') is null
			set @parXML.modify ('insert attribute contam {sql:variable("@contam")} into (/row/row/detalii/row)[1]') 
		if @parXML.value('(/row/row/detalii/row/@contam)[1]', 'varchar(40)') = ''
			set @parXML.modify('replace value of (/row/row/detalii/row/@contam)[1] with sql:variable("@contam")')
	end
	if @parXML.value('(/row/row/detalii/row/@tipam)[1]', 'char(1)') is null
		set @parXML.modify ('insert attribute tipam {sql:variable("@tipam")} into (/row/row/detalii/row)[1]') 
end

--	subtip=TR (transfer retur cu gestiune predatoare tip I) completez in parXML codul de nomenclator (=cod din mfix.detalii completat la momentul TE initial) si codiprimitor=codintrare
if @tip='TE' and @subtip='TR'
begin
	select 
		@gestiune=isnull(@parXML.value('(/row/row/@gestiune)[1]','varchar(13)'),isnull(@parXML.value('(/row/@gestiune)[1]','varchar(13)'),'')),
		@cod=rtrim(isnull(@parXML.value('(/row/row/@cod)[1]', 'varchar(25)'),'')),
		@nrinv=rtrim(isnull(@parXML.value('(/row/linie/@codiprimitor)[1]', 'varchar(25)'), @parXML.value('(/row/row/@codiprimitor)[1]', 'varchar(25)')))

	if isnull((select tip_gestiune from gestiuni where Subunitate=@subunitate and Cod_gestiune=@gestiune),'')='I'
	begin
		set @nrinv=isnull(@parXML.value('(/row/row/@codintrare)[1]', 'varchar(25)'),'')
		select @cod=detalii.value('(/row/@cod)[1]', 'varchar(25)') from mfix where Numar_de_inventar=@nrinv

		if @parXML.value('(/row/row/@cod)[1]', 'varchar(25)') is null
			set @parXML.modify ('insert attribute cod {sql:variable("@cod")} into (/row/row)[1]')

		if @parXML.value('(/row/row/@codiprimitor)[1]', 'varchar(25)') is null
			set @parXML.modify ('insert attribute codiprimitor {sql:variable("@nrinv")} into (/row/row)[1]') 
	end
end

--	am pus la final validarea pt. a face validare contului de amortizare la RM (dupa formarea acestuia)
exec wValidareMFdinCG @sesiune, @parXML

end try

begin catch
	set @eroare=ERROR_MESSAGE()+' (wPregatireMFdinCG)'
	if @eroare is not null raiserror(@eroare,16,1)
end catch
	
