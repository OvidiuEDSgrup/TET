--***
create procedure wIaConfigMachete_Grid (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(500), @meniu varchar(20), @tip varchar(10), @subtip varchar(10), @nivel int,
		@fg_meniu varchar(20), @fg_tip varchar(20), @fg_subtip varchar(20), @fg_nume varchar(100), @fg_vizibil varchar(3), @fg_inpozitii varchar(3),
				--> parametri "@nec_" determina modul de filtrare: daca filtrul asociat contine doar spatii se vor aduce doar datele pt care campul corespunzator este necompletat, altfel se filtreaza cu like
		@nec_meniu bit, @nec_tip bit, @nec_subtip bit, @nec_nume bit
begin try

	set @meniu = isnull(@parXML.value('(/*/@meniu)[1]','varchar(20)'),'')
	set @tip = isnull(@parXML.value('(/*/@tip_m)[1]','varchar(10)'),'')
	set @subtip = isnull(@parXML.value('(/*/@subtip_m)[1]','varchar(10)'),'')
	set @nivel = @parXML.value('(/*/@nivel)[1]','int')

	select @fg_meniu = isnull(@parXML.value('(/*/@fg_meniu)[1]','varchar(20)'),''),
		@fg_tip = isnull(@parXML.value('(/*/@fg_tip)[1]','varchar(20)'),''),
		@fg_subtip = isnull(@parXML.value('(/*/@fg_subtip)[1]','varchar(20)'),''),
		@fg_nume = isnull(@parXML.value('(/*/@fg_nume)[1]','varchar(100)'),''),
		@fg_vizibil = isnull(@parXML.value('(/*/@fg_vizibil)[1]','varchar(3)'),''),
		@fg_inpozitii = isnull(@parXML.value('(/*/@fg_inpozitii)[1]','varchar(3)'),'')
	
	select	@nec_meniu=(case when rtrim(@fg_meniu)='' and @parXML.value('string-length(/*[1]/@fg_meniu)', 'int')>0 then 1 else 0 end),
			@nec_tip=(case when rtrim(@fg_tip)='' and @parXML.value('string-length(/*[1]/@fg_tip)', 'int')>0 then 1 else 0 end),
			@nec_subtip=(case when rtrim(@fg_subtip)='' and @parXML.value('string-length(/*[1]/@fg_subtip)', 'int')>0 then 1 else 0 end),
			@nec_nume=(case when rtrim(@fg_nume)='' and @parXML.value('string-length(/*[1]/@fg_nume)', 'int')>0 then 1 else 0 end),
			@fg_meniu='%' + @fg_meniu + '%',
			@fg_tip='%' + @fg_tip + '%',
			@fg_subtip='%' + @fg_subtip + '%',
			@fg_nume='%' + @fg_nume + '%'
			
	set @fg_vizibil=(case when @fg_vizibil in ('da','1') then '1' when @fg_vizibil in ('nu','0') then '0' else '' end)
	set @fg_inpozitii=(case when @fg_inpozitii in ('da','1') then '1' when @fg_inpozitii in ('nu','0') then '0' else '' end)

	if @nivel < 0
	begin
		set @mesaj = 'Nivel invalid.'
		raiserror(@mesaj,16,1)
	end

	select	wg.Meniu g_meniu,
			wg.Tip g_tip,
			wg.Subtip g_subtip,
			case when wg.InPozitii=1 then 'Da' else 'Nu' end g_in_pozitii_,
			wg.InPozitii g_in_pozitii,
			wg.NumeCol g_nume_col,
			wg.DataField g_data_field,
			wg.TipObiect g_tip_obiect,
			(case wg.TipObiect	when 'C' then 'Alfanumeric (C)'
								when 'D' then 'Data calendaristica (D)'
								when 'N' then 'Numeric (N)'
								when 'T' then 'TextArea (T)'
								when 'AC' then 'AutoComplete (AC)'
								when 'CB' then 'ComboBox (CB)'
								when 'CF' then 'Cod fiscal (CF)'
								when 'CHB' then 'CheckBox (CHB)'
								when 'IN' then 'Input (upload fisiere) (IN)'
								else wg.TipObiect end) g_tip_obiect_,
			wg.Latime g_latime,
			wg.Ordine g_ordine,
			case when wg.Vizibil=1 then 'Da' else 'Nu' end g_vizibil_,
			wg.Vizibil g_vizibil,
			case when wg.modificabil=1 then 'Da' else 'Nu' end g_modificabil_,
			wg.Modificabil g_modificabil,
			wg.Formula g_formula
	from	webconfiggrid wg 
	where	(wg.Meniu=@meniu  or exists (select 1 from webConfigmeniu w where w.meniuparinte=@meniu and w.meniu=wg.Meniu))
			and (@tip='' or wg.Tip=@tip) 
			and (@subtip='' or wg.Subtip=@subtip)
		and	(@nec_meniu=1 and isnull(rtrim(wg.meniu),'')='' or @nec_meniu=0 and isnull(wg.Meniu,'') like @fg_meniu)
		and	(@nec_tip=1 and isnull(rtrim(wg.tip),'')='' or @nec_tip=0 and isnull(wg.Tip,'') like @fg_tip)
		and	(@nec_subtip=1 and isnull(rtrim(wg.subtip),'')='' or @nec_subtip=0 and isnull(wg.Subtip,'') like @fg_subtip)
		and	(@nec_nume=1 and isnull(rtrim(wg.NumeCol),'')='' or @nec_nume=0 and isnull(wg.NumeCol,'') like @fg_nume)
		and	(@fg_vizibil='' or convert(varchar(1),wg.Vizibil)=@fg_vizibil)
		and	(@fg_inpozitii='' or convert(varchar(1),wg.InPozitii)=@fg_inpozitii)
	order by wg.Meniu, isnull(wg.Tip,''), isnull(wg.Subtip,''), wg.Ordine
	for xml raw

end try
begin catch
	set @mesaj = error_message() + ' (wIaConfigMachete_Grid)'
	raiserror(@mesaj, 11, 1)
end catch
