--***
create procedure wIaConfigMachete_Filtre (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(500), @meniu varchar(20), @tip varchar(10), @subtip varchar(10), @nivel int,
		@ft_meniu varchar(20), @ft_tip varchar(20), @ft_descriere varchar(100), @ft_vizibil varchar(3), @ft_interval varchar(3),
				--> parametri "@nec_" determina modul de filtrare: daca filtrul asociat contine doar spatii se vor aduce doar datele pt care campul corespunzator este necompletat, altfel se filtreaza cu like
		@nec_meniu bit, @nec_tip bit, @nec_descriere bit

begin try

	select	@meniu = isnull(@parXML.value('(/*/@meniu)[1]','varchar(20)'),''),
			@tip = isnull(@parXML.value('(/*/@tip_m)[1]','varchar(10)'),''),
			@subtip = rtrim(isnull(@parXML.value('(/*/@subtip_m)[1]','varchar(10)'),'')),
			@nivel = @parXML.value('(/*/@nivel)[1]','int'),
		@ft_meniu = isnull(@parXML.value('(/*/@ft_meniu)[1]','varchar(20)'),''),
		@ft_tip = isnull(@parXML.value('(/*/@ft_tip)[1]','varchar(20)'),''),
		@ft_descriere = isnull(@parXML.value('(/*/@ft_descriere)[1]','varchar(100)'),''),
		@ft_vizibil = isnull(@parXML.value('(/*/@ft_vizibil)[1]','varchar(3)'),''),
		@ft_interval = isnull(@parXML.value('(/*/@ft_interval)[1]','varchar(3)'),'')
	
	select @nec_meniu=(case when rtrim(@ft_meniu)='' and @parXML.value('string-length(/*[1]/@ft_meniu)', 'int')>0 then 1 else 0 end),
		@nec_tip=(case when rtrim(@ft_tip)='' and @parXML.value('string-length(/*[1]/@ft_tip)', 'int')>0 then 1 else 0 end),
		@nec_descriere=(case when rtrim(@ft_descriere)='' and @parXML.value('string-length(/*[1]/@ft_descriere)', 'int')>0 then 1 else 0 end),
		@ft_meniu='%' + @ft_meniu + '%',
		@ft_tip='%' + @ft_tip + '%',
		@ft_descriere='%' + @ft_descriere  + '%'

	set @ft_vizibil=(case when @ft_vizibil in ('da','1') then '1' when @ft_vizibil in ('nu','0') then '0' else '' end)
	set @ft_interval=(case when @ft_interval in ('da','1') then '1' when @ft_interval in ('nu','0') then '0' else '' end)

	if @nivel < 0
	begin
		set @mesaj = 'Nivel invalid.'
		raiserror(@mesaj,16,1)
	end

	if (@subtip='')
	
	select	wf.Meniu t_meniu,
			wf.Tip t_tip,
			wf.Ordine t_ordine,
			case when wf.Vizibil=1 then 'Da' else 'Nu' end t_vizibil_,
			wf.Vizibil t_vizibil,
			wf.TipObiect t_tip_obiect,
			wf.Descriere t_descriere,
			wf.Prompt1 t_prompt1,
			wf.DataField1 t_datafield1,
			case when wf.Interval=1 then 'Da' else 'Nu' end t_interval_,
			wf.Interval t_interval,
			wf.Prompt2 t_prompt2,
			wf.DataField2 t_datafield2
	from	webconfigfiltre wf 
	where	(wf.Meniu=@meniu or exists (select 1 from webConfigmeniu m where m.meniuparinte=@meniu and wf.Meniu=m.meniu))
			and (@tip='' or wf.Tip=@tip)
			and (@nec_meniu=1 and rtrim(isnull(wf.meniu,''))='' or @nec_meniu=0 and rtrim(isnull(wf.meniu,'')) like @ft_meniu)
			and (@nec_tip=1 and rtrim(isnull(wf.tip,''))='' or @nec_tip=0 and rtrim(isnull(wf.tip,'')) like @ft_tip)
			and (@nec_descriere=1 and rtrim(isnull(wf.descriere,''))='' or @nec_descriere=0 and rtrim(isnull(wf.descriere,'')) like @ft_descriere)
			and	(@ft_vizibil='' or convert(varchar(1),wf.Vizibil)=@ft_vizibil)
			and	(@ft_interval='' or convert(varchar(1),wf.Interval)=@ft_interval)
	order by wf.Meniu, wf.Tip, wf.Ordine
	for xml raw

end try

begin catch
	set @mesaj = error_message() + ' (wIaConfigMachete_Filtre)'
	raiserror(@mesaj, 11, 1)
end catch
