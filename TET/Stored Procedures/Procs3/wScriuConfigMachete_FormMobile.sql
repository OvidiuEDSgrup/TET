--***
create procedure wScriuConfigMachete_FormMobile (@sesiune varchar(50), @parXML xml)
as
	declare @eroare varchar(max),
		@Identificator varchar(100),
		@Ordine float,
		@Nume varchar(50),
		@TipObiect varchar(50),
		@DataField varchar(50),
		@LabelField varchar(50),
		@ProcSQL varchar(50),
		@ListaValori varchar(100),
		@ListaEtichete varchar(600),
		@Initializare varchar(50),
		@Prompt varchar(50),
		@Vizibil bit,
		@Modificabil bit,
		@o_Identificator varchar(100),
		@o_datafield varchar(50),
		@o_ordine float,
		@update bit

begin try
	select @Identificator = @parXML.value('(/row/@identificator)[1]','varchar(100)'),
		@Ordine = @parXML.value('(/row/@ordine)[1]','float'),
		@Nume = @parXML.value('(/row/@nume)[1]','varchar(50)'),
		@TipObiect = @parXML.value('(/row/@tipobiect)[1]','varchar(50)'),
		@DataField = @parXML.value('(/row/@datafield)[1]','varchar(50)'),
		@LabelField = @parXML.value('(/row/@labelfield)[1]','varchar(50)'),
		@ProcSQL = @parXML.value('(/row/@procsql)[1]','varchar(50)'),
		@ListaValori = @parXML.value('(/row/@listavalori)[1]','varchar(100)'),
		@ListaEtichete = @parXML.value('(/row/@listaetichete)[1]','varchar(600)'),
		@Initializare = @parXML.value('(/row/@initializare)[1]','varchar(50)'),
		@Prompt = @parXML.value('(/row/@prompt)[1]','varchar(50)'),
		@Vizibil = @parXML.value('(/row/@vizibil)[1]','bit'),
		@Modificabil = @parXML.value('(/row/@modificabil)[1]','bit'),
		@o_Identificator = @parXML.value('(/row/@o_identificator)[1]','varchar(100)'),
		@o_datafield = @parXML.value('(/row/@o_datafield)[1]','varchar(50)'),
		@o_Ordine = @parXML.value('(/row/@o_ordine)[1]','float')
		
	set @update = case when @o_Identificator is null then 0 else 1 end
	
	if isnull(@Identificator,'')=''
	begin
		set @eroare = 'Identificatorul nu este completat.'
		raiserror(@eroare,16,1)
	end
	
	if (@ordine < 0)
	begin
		set @eroare = 'Numarul de ordine trebuie sa fie mai mare decat 0.'
		raiserror(@eroare,16,1)
	end
	
	if exists(select 1 from webConfigFormMobile wf 
					where wf.identificator = @identificator
					and (isnull(wf.DataField,'')=isnull(@datafield,''))
			) and (@update=0)
	begin
		set @eroare = 'Acest form deja exista in webConfigFormMobile.'
		raiserror(@eroare,16,1)
	end
	
	/* Se renumeroteaza toate campurile*/
	select identificator, datafield,row_number() over (order by ordine,nume)+(case when row_number() over (order by ordine,nume)<@ordine or @update=1 then 0 else 1 end) ordine
		into #ptOrdine
		from webconfigformmobile
			where identificator=@identificator

	update v 
		set ordine=n.ordine+
			(case when @o_ordine is null then 0
				when v.ordine>@o_ordine and v.ordine<=@ordine then -1
				when v.ordine>=@ordine and v.ordine<@o_ordine then 1
				else 0 
			 end)
	from webconfigformmobile v
	inner join #ptOrdine n on v.identificator=n.identificator and v.DataField=n.DataField
	
	if @ordine=0
		set @ordine=1
		
	if @update=0
	begin
		insert into webConfigFormMobile(Identificator, Ordine, Nume, TipObiect, DataField, LabelField, ProcSQL, ListaValori, ListaEtichete, Initializare, Prompt, Vizibil, Modificabil)
		select @Identificator, @Ordine, @Nume, @TipObiect, @DataField, @LabelField, @ProcSQL, @ListaValori, @ListaEtichete, @Initializare, @Prompt, @Vizibil, @Modificabil
	end
	else
	begin
		update webconfigformmobile
		set Identificator=@Identificator, Nume=@Nume, TipObiect=@TipObiect, DataField=@DataField, LabelField=@LabelField, ProcSQL=@ProcSQL,
			ListaValori=@ListaValori, ListaEtichete=@ListaEtichete, Initializare=@Initializare, Prompt=@Prompt, Vizibil=@Vizibil, Modificabil=@Modificabil,
			ordine=(case when @ordine=@o_ordine then ordine else @ordine end)
		where identificator=@o_identificator
			and isnull(DataField,'')=isnull(@o_datafield,'')
	end
	
	exec wIaConfigMachete_FormMobile @sesiune=@sesiune, @parXML=@parXML
end try
begin catch
	set @eroare = error_message() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@eroare, 11, 1)
end catch
