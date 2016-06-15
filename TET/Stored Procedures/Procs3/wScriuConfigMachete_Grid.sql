--***
create procedure wScriuConfigMachete_Grid (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(500), @g_meniu varchar(20), @g_tip varchar(20), @g_subtip varchar(20), @g_in_pozitii bit, @g_nume_col varchar(50), @g_data_field varchar(50),
		@g_tip_obiect varchar(50), @g_latime int, @g_ordine int, @g_vizibil bit, @g_modificabil bit, @g_formula varchar(max),
		@o_meniu varchar(20), @o_tip varchar(20), @o_subtip varchar(20), @o_data_field varchar(50), @o_in_pozitii bit, @update bit,
		@o_ordine int

begin try
	set @g_meniu = @parXML.value('(/row/@g_meniu)[1]','varchar(20)')
	set @g_tip = @parXML.value('(/row/@g_tip)[1]','varchar(20)')
	set @g_subtip = @parXML.value('(/row/@g_subtip)[1]','varchar(20)')
	set @g_in_pozitii = isnull(@parXML.value('(/row/@g_in_pozitii)[1]','bit'),0)
	set @g_nume_col = @parXML.value('(/row/@g_nume_col)[1]','varchar(50)')
	set @g_data_field = @parXML.value('(/row/@g_data_field)[1]','varchar(50)')
	set @g_tip_obiect = @parXML.value('(/row/@g_tip_obiect)[1]','varchar(50)')
	set @g_latime = @parXML.value('(/row/@g_latime)[1]','int')
	set @g_ordine = isnull(@parXML.value('(/row/@g_ordine)[1]','int'),0)
	set @g_vizibil = isnull(@parXML.value('(/row/@g_vizibil)[1]','bit'),0)
	set @g_modificabil = isnull(@parXML.value('(/row/@g_modificabil)[1]','bit'),0)
	set @g_formula = @parXML.value('(/row/@g_formula)[1]','varchar(max)')

	set @o_meniu = isnull(@parXML.value('(/row/@o_g_meniu)[1]','varchar(20)'),'')
	set @o_tip = @parXML.value('(/row/@o_g_tip)[1]','varchar(20)')
	set @o_subtip = @parXML.value('(/row/@o_g_subtip)[1]','varchar(20)')
	set @o_data_field = @parXML.value('(/row/@o_g_data_field)[1]','varchar(50)')
	set @o_in_pozitii = @parXML.value('(/row/@o_g_in_pozitii)[1]','bit')
	set @o_ordine = @parXML.value('(/row/@o_g_ordine)[1]','int')

	set @update = (case when @o_meniu='' then 0 else 1 end)

	if isnull(@g_meniu,'')=''
	begin
		set @mesaj = 'Meniul nu este completat.'
		raiserror(@mesaj,16,1)
	end

	if (@g_ordine < 1)
	begin
		set @mesaj = 'Numarul de ordine trebuie sa fie mai mare decat 0.'
		raiserror(@mesaj,16,1)
	end

	-- Se verifica sa nu existe deja acest grid
	if exists(select 1 from webConfigGrid wg
					where wg.Meniu = @g_meniu
					and (isnull(wg.Tip,'')=isnull(@g_tip,''))
					and (isnull(wg.Subtip,'')=isnull(@g_subtip,''))
					and (isnull(wg.DataField,'')=isnull(@g_data_field,''))
					and (isnull(wg.InPozitii,0)=isnull(@g_in_pozitii,0))
			) and (@update=0)
	begin
		set @mesaj = 'Acest grid deja exista in webConfigGrid.'
		raiserror(@mesaj,16,1)
	end

	/* Se renumeroteaza toate campurile*/
	select meniu,tip,subtip,datafield,inpozitii,row_number() over (order by ordine,numecol)+(case when row_number() over (order by ordine,numecol)<@g_ordine or @update=1 then 0 else 1 end) ordine
		into #ptOrdine
		from webconfiggrid
			where Meniu=@g_meniu
			and isnull(Tip,'')=isnull(@g_tip,'') 
			and isnull(Subtip,'')=isnull(@g_subtip,'')
			and (isnull(InPozitii,0)=isnull(@g_in_pozitii,0))

	update v 
		set ordine=n.ordine+
			(case when @o_ordine is null then 0
				when v.ordine>@o_ordine and v.ordine<=@g_ordine then -1
				when v.ordine>=@g_ordine and v.ordine<@o_ordine then 1
				else 0 
			 end)
	from webConfiggrid v
	inner join #ptOrdine n on v.meniu=n.meniu and isnull(v.tip,'')=isnull(n.tip,'') and isnull(v.Subtip,'')=isnull(n.Subtip,'') and isnull(v.DataField,'')=isnull(n.DataField,'') and n.inpozitii=v.inpozitii

	if @g_ordine=0
		set @g_ordine=1
		
	if @update=0
	begin
		insert into webConfigGrid(Meniu, Tip, Subtip, InPozitii, NumeCol, DataField, TipObiect, Latime, Ordine, Vizibil, modificabil, formula, detalii)
		values(@g_meniu, @g_tip, @g_subtip, @g_in_pozitii, @g_nume_col, @g_data_field, @g_tip_obiect, @g_latime, @g_ordine, @g_vizibil, @g_modificabil, @g_formula,null)
	end
	else
	begin
		update webConfigGrid
		set Meniu=@g_meniu, Tip=@g_tip, Subtip=@g_subtip, InPozitii=@g_in_pozitii, NumeCol=@g_nume_col, DataField=@g_data_field, TipObiect=@g_tip_obiect,
			Latime=@g_latime, Ordine=(case when @g_ordine=@o_ordine then ordine else @g_ordine end), Vizibil=@g_vizibil, Modificabil=@g_modificabil, formula=@g_formula
		where Meniu=@o_meniu
			and isnull(Tip,'')=isnull(@o_tip,'') 
			and isnull(Subtip,'')=isnull(@o_subtip,'')
			and isnull(DataField,'')=isnull(@o_data_field,'')
			and isnull(InPozitii,0)=isnull(@o_in_pozitii,0)
	end

	exec wIaConfigMachete_Grid @sesiune=@sesiune, @parXML=@parXML
end try

begin catch
	set @mesaj = error_message() + ' (wScriuConfigMachete_Grid)'
	raiserror(@mesaj, 11, 1)
end catch
