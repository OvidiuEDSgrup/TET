--***
create procedure wIaConfigMachete_Taburi (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(500), @meniu varchar(20), @tip varchar(10), @subtip varchar(10), @nivel int,
		@fb_meniu varchar(20), @fb_numetab varchar(100), @fb_tipmach varchar(50), @fb_meniunou varchar(50), @fb_tipnou varchar(50), @fb_vizibil varchar(3),
			--> parametri "@nec_" determina modul de filtrare: daca filtrul asociat contine doar spatii se vor aduce doar datele pt care campul corespunzator este necompletat, altfel se filtreaza cu like
		@nec_meniu bit, @nec_numetab bit, @nec_tipmach bit, @nec_meniunou bit, @nec_tipnou bit

begin try

	select
			@meniu = isnull(@parXML.value('(/*/@meniu)[1]','varchar(20)'),''),
			@tip = isnull(@parXML.value('(/*/@tip_m)[1]','varchar(10)'),''),
			@subtip = rtrim(isnull(@parXML.value('(/*/@subtip_m)[1]','varchar(10)'),'')),
			@nivel = @parXML.value('(/*/@nivel)[1]','int'),
		@fb_meniu = isnull(@parXML.value('(/*/@fb_meniu)[1]','varchar(20)'),''),
		@fb_numetab = isnull(@parXML.value('(/*/@fb_numetab)[1]','varchar(100)'),''),
		@fb_tipmach = isnull(@parXML.value('(/*/@fb_tipmach)[1]','varchar(50)'),''),
		@fb_meniunou = isnull(@parXML.value('(/*/@fb_meniunou)[1]','varchar(50)'),''),
		@fb_tipnou = isnull(@parXML.value('(/*/@fb_tipnou)[1]','varchar(50)'),''),
		@fb_vizibil = isnull(@parXML.value('(/*/@fb_vizibil)[1]','varchar(3)'),'')

	select @nec_meniu=(case when rtrim(@fb_meniu)='' and @parXML.value('string-length(/*[1]/@fb_meniu)', 'int')>0 then 1 else 0 end),
		@nec_numetab=(case when rtrim(@fb_numetab)='' and @parXML.value('string-length(/*[1]/@fb_numetab)', 'int')>0 then 1 else 0 end),
		@nec_tipmach=(case when rtrim(@fb_tipmach)='' and @parXML.value('string-length(/*[1]/@fb_tipmach)', 'int')>0 then 1 else 0 end),
		@nec_meniunou=(case when rtrim(@fb_meniunou)='' and @parXML.value('string-length(/*[1]/@fb_meniunou)', 'int')>0 then 1 else 0 end),
		@nec_tipnou=(case when rtrim(@fb_tipnou)='' and @parXML.value('string-length(/*[1]/@fb_tipnou)', 'int')>0 then 1 else 0 end),
		@fb_meniu='%' + @fb_meniu + '%',
		@fb_numetab='%' + @fb_numetab  + '%',
		@fb_tipmach='%' + @fb_tipmach + '%',
		@fb_meniunou='%' + @fb_meniunou + '%',
		@fb_tipnou='%' + @fb_tipnou + '%'
				
	
	set @fb_vizibil=(case when @fb_vizibil in ('da','1') then '1' when @fb_vizibil in ('nu','0') then '0' else '' end)

	if @nivel < 0
	begin
		set @mesaj = 'Nivel invalid.'
		raiserror(@mesaj,16,1)
	end

	if (@subtip='')
	begin
		begin
			select	wt.MeniuSursa b_meniu_sursa,
					wt.TipSursa b_tip_sursa,
					wt.NumeTab b_nume_tab,
					wt.Icoana b_icoana,
					wt.TipMachetaNoua b_tip_macheta,
					wt.MeniuNou b_cod_meniu,
					wt.TipNou b_tip_doc,
					wt.ProcPopulare b_proc_populare,
					wt.Ordine b_ordine,
					case when wt.Vizibil=1 then 'Da' else 'Nu' end b_vizibil_,
					wt.Vizibil b_vizibil
			from	webConfigTaburi wt
			where	(wt.MeniuSursa=@meniu or exists (select 1 from webConfigmeniu m where m.meniuparinte=@meniu and wt.MeniuSursa=m.Meniu))
				and (@tip='' or wt.tipsursa=@tip)
				and	(@nec_meniu=1 and rtrim(isnull(wt.meniusursa,''))='' or @nec_meniu=0 and rtrim(isnull(wt.MeniuSursa,'')) like @fb_meniu)
				and	(@nec_numetab=1 and rtrim(isnull(wt.NumeTab,''))='' or @nec_numetab=0 and rtrim(isnull(wt.numetab,'')) like @fb_numetab)
				and	(@nec_tipmach=1 and rtrim(isnull(wt.TipMachetaNoua,''))='' or @nec_tipmach=0 and rtrim(isnull(wt.TipMachetaNoua,'')) like @fb_tipmach)
				and	(@nec_meniunou=1 and rtrim(isnull(wt.MeniuNou,''))='' or @nec_meniunou=0 and rtrim(isnull(wt.MeniuNou,'')) like @fb_meniunou)
				and	(@nec_tipnou=1 and rtrim(isnull(wt.TipNou,''))='' or @nec_tipnou=0 and rtrim(isnull(wt.TipNou,'')) like @fb_tipnou)
				and	(@fb_vizibil='' or convert(varchar(1),wt.Vizibil)=@fb_vizibil)
			order by wt.MeniuSursa, wt.TipSursa, wt.MeniuNou, wt.Ordine
			for xml raw
		end
	end

end try

begin catch
	set @mesaj = error_message() + ' (wIaConfigMachete_Taburi)'
	raiserror(@mesaj, 11, 1)
end catch
