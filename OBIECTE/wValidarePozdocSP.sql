--***
if exists (select * from sysobjects where name ='wfValidarePozdocMF')
drop function wfValidarePozdocMF
go
if exists (select * from sysobjects where name ='wValidarePozdocMF')
drop procedure wValidarePozdocMF
go
--***
Create procedure wValidarePozdocMF (@sesiune varchar(50), @document xml)
as 
begin
	declare @modimpl int, @rulajepelm int, @datal datetime, @tip varchar(2), @subtip varchar(2), 
		@sub varchar(9), @numar varchar(8), @data datetime, @nrinv varchar(13), @contmf varchar(13), 
		@contcor varchar(13), @mesaj varchar(255)
	
	exec luare_date_par 'MF', 'IMPLEMENT', @modimpl output, 0, ''
	exec luare_date_par 'GE', 'RULAJELM', @rulajepelm output, 0, ''
	set @datal=isnull(@document.value('(/row/@datal)[1]','datetime'),'01/01/1901')
	set @tip=isnull(@document.value('(/row/@tip)[1]', 'varchar(2)'),'')
	set @subtip=isnull(@document.value('(/row/row/@subtip)[1]', 'varchar(2)'),'')
	set @sub=isnull(@document.value('(/row/row/@sub)[1]', 'varchar(9)'),'')
	set @numar=isnull(@document.value('(/row/row/@numar)[1]', 'varchar(8)'),'')
	set @data=isnull(@document.value('(/row/row/@data)[1]', 'datetime'), isnull(@document.value('(/row/@data)[1]', 'datetime'), '01/01/1901'))
	set @nrinv=isnull(@document.value('(/row/row/@nrinv)[1]', 'varchar(13)'), isnull(@document.value('(/row/@nrinv)[1]', 'varchar(13)'), ''))
	if @tip='MI' set @contmf=isnull(@document.value('(/row/row/@contmf)[1]', 'varchar(13)'), '')
	if @tip<>'MI' set @contmf=(select top 1 f.cont_mijloc_fix
			FROM fisamf f WHERE /*f.subunitate = @sub and */f.numar_de_inventar = @nrinv 
			and f.felul_operatiei='1' and f.data_lunii_operatiei <= @datal 
			order by f.data_lunii_operatiei desc)
	if @tip<>'MI' and @contmf is null select @contmf=f.cont_mijloc_fix
			FROM fisamf f WHERE /*f.subunitate = @sub and */f.numar_de_inventar = @nrinv 
			and f.felul_operatiei in ('2','3') --and f.data_lunii_operatiei = @datal
	set @contcor=isnull(@document.value('(/row/row/@contcor)[1]', 'varchar(13)'), '')

	if @document.exist('/row/row')=1 and @numar = '' and @modimpl=0
	begin
		raiserror('Nr. doc. necompletat!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@update)[1]', 'int'), 0)=1
	and @numar <> isnull(@document.value('(/row/row/@o_numar)[1]', 'char(8)'), '') 
	--and @subtip in ('AF','FF','VI')
	begin
		raiserror('Nr. doc. nu se poate schimba!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 --and isnull(@document.value('(/row/row/@update)[1]', 'int'), 0)=1
	and @data <> dbo.eom(@data) and @tip in ('MM') and @subtip in ('RE')
	begin
		raiserror('Data doc. trebuie sa fie data ultimei zile din luna aleasa!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@update)[1]', 'int'), 0)=1
	and @data <> isnull(@document.value('(/row/row/@o_data)[1]', 'datetime'), '01/01/1901') 
	--and @subtip in ('AF','FF','VI')
	begin
		raiserror('Data doc. nu se poate schimba!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and (@data < dbo.bom(@datal) or @data > dbo.eom(@datal)) 
	--and @subtip in ('AF','FF','VI')
	begin
		raiserror('Data doc. nu este in luna aleasa!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 --and @nrinv 
	--and isnull(@document.value('(/row/row/@sub)[1]', 'char(9)'), '') <>'DENS'
	and @datal>(SELECT mm.Data_lunii_de_miscare FROM misMF mm WHERE /*mm.subunitate=@sub and */
	mm.Numar_de_inventar=@nrinv and LEFT(mm.tip_miscare,1)='I') 
	/*daca se face impl. ca in MF, tb. si data<=data impl.!!!*/ and @tip<>'MI' --in ('ME','MM')
	and not exists (select 1 from fisamf where felul_operatiei='1' 
	and data_lunii_operatiei=dbo.bom(@datal)-1 and numar_de_inventar=@nrinv)
	begin
		raiserror('Dati calcule lunare pe luna(ile) anterioara(e) la acest nr. de inventar!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@update)[1]', 'int'), 0) =1
	and @nrinv <> isnull(@document.value('(/row/row/@o_nrinv)[1]', 'char(13)'), '') 
	--and @subtip in ('AF','FF','VI')
	begin
		raiserror('Mijlocul fix nu se poate schimba!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and @nrinv = ''
	--and @subtip in ('AF','FF','VI')
	begin
		raiserror('Nr. de inventar necompletat!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@update)[1]', 'int'), 0) = 0 
	and @tip in ('MI')
	and exists (select 1 from mfix 
	where numar_de_inventar=@nrinv)
	begin
		raiserror('Nr. de inventar existent!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 --and @nrinv 
	and @tip not in ('MI')
	and not exists (select 1 from mfix 
	where numar_de_inventar=@nrinv)
	begin
		raiserror('Nr. de inventar inexistent!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@update)[1]', 'int'), 0) = 0 
	and exists (select 1 from mismf where subunitate<>'DENS' and Numar_document=@numar 
	and data_lunii_de_miscare=@datal and numar_de_inventar=@nrinv /*and Data_miscarii=@data*/)
	begin
		raiserror('Exista deja un doc. cu acest nr. pe aceasta luna la acest nr. de inventar!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@update)[1]', 'int'), 0) = 0 
	and (@tip not in ('MT') or @rulajepelm=1) and exists (select 1 from mismf where subunitate<>'DENS' 
	and tip_miscare=right(@tip,1)+@subtip and data_lunii_de_miscare=@datal and numar_de_inventar=@nrinv) 
	and right(@tip,1)+@subtip in ('MTP','MEP','MRE','MMA','BIN','CON','RCI','SCO','TSE')
	begin
		raiserror('Exista deja un astfel de subtip de doc. pe aceasta luna la acest nr. de inventar!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@update)[1]', 'int'), 0) = 0 
	and @tip in ('MT') and exists (select 1 from mismf where subunitate<>'DENS' 
	and left(tip_miscare,1)=RIGHT(@tip,1) and data_lunii_de_miscare=@datal and numar_de_inventar=@nrinv 
	and data_miscarii=@data)
	begin
		raiserror('Exista deja un astfel de tip de doc. pe aceasta data la acest nr. de inventar!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@update)[1]', 'int'), 0) = 0 
	and @tip in ('ME') and exists (select 1 from mismf where subunitate<>'DENS' 
	and left(tip_miscare,1)=RIGHT(@tip,1) and numar_de_inventar=@nrinv)
	begin
		raiserror('Exista deja un astfel de tip de doc. la acest nr. de inventar!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 --and isnull(@document.value('(/row/row/@update)[1]', 'int'), 0) = 0 
	and @tip in ('MM') and exists (select 1 from mismf where subunitate<>'DENS' 
	and numar_de_inventar=@nrinv and Data_miscarii>@data and LEFT(tip_miscare,1) in ('M','T'))
	begin
		raiserror('Exista un doc. (modif. / transfer) ulterior la acest nr. de inventar! Stergeti acel doc. si apoi adaugati / modif. / stergeti doc. curent.',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@denmf)[1]', 'char(80)'), '') = ''
	and @tip in ('MI')
	begin
		raiserror('Denumire necompletata!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 --and isnull(@document.value('(/row/row/@codcl)[1]', 'char(13)'), '') = ''
	and @tip in ('MI')
	and not exists (select 1 from codclasif where 
	cod_de_clasificare=isnull(@document.value('(/row/row/@codcl)[1]', 'char(13)'), ''))
	begin
		raiserror('Cod de clasificare inexistent!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 --and isnull(@document.value('(/row/row/@tert)[1]', 'char(13)'), '') = ''
	and @subtip in ('AF','FF','VI')
	and not exists (select 1 from terti where 
	tert=isnull(@document.value('(/row/row/@tert)[1]', 'char(13)'), ''))
	begin
		raiserror('Tert inexistent!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@fact)[1]', 'char(20)'), '') = ''
	and @subtip in ('AF','FF','VI')
	begin
		raiserror('Factura necompletata!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@datascad)[1]', 'datetime'), '01/01/1901') < isnull(@document.value('(/row/row/@datafact)[1]', 'datetime'), '01/01/1901') 
	and @subtip in ('AF','FF','VI')
	begin
		raiserror('Data scadentei < data facturii!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@curs)[1]', 'float'), 0) = 0
	and isnull(@document.value('(/row/row/@valuta)[1]', 'char(3)'), '') <> ''
	--and @subtip in ('AF','FF','VI')
	begin
		raiserror('Curs necompletat!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@pretvaluta)[1]', 'float'), 0) = 0
	and isnull(@document.value('(/row/row/@valuta)[1]', 'char(3)'), '') <> ''
	--and @subtip in ('AF','FF','VI')
	begin
		raiserror('Pret in valuta necompletat!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@valinv)[1]', 'float'), 0) = 0
	and @tip in ('MI')
	begin
		raiserror('Valoare de inventar necompletata!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@cotatva)[1]', 'float'), 0) = 0
	and isnull(@document.value('(/row/row/@sumatva)[1]', 'float'), 0) <> 0
	and @subtip in ('AF','FF','VI','CS')
	begin
		raiserror('Suma TVA completata si cota TVA necompletata!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@sumatva)[1]', 'float'), 0) = 0
	and isnull(@document.value('(/row/row/@cotatva)[1]', 'float'), 0) <> 0
	and @subtip in (/*'AF','FF','VI',*/'CS')
	begin
		raiserror('Suma TVA necompletata si cota TVA completata!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 --and isnull(@document.value('(/row/row/@gest)[1]', 'char(9)'), '') = ''
	and @tip in ('MI')
	and not exists (select 1 from gestiuni where tip_gestiune='I' and 
	cod_gestiune=isnull(@document.value('(/row/row/@gest)[1]', 'char(9)'), ''))
	begin
		raiserror('Gestiunea nu exista sau nu este de tip I-Imobilizari!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 --and isnull(@document.value('(/row/row/@contgestprim)[1]', 'char(13)'), '') = ''
	and @tip in ('MT')
	and not exists (select 1 from gestiuni where tip_gestiune='I' and 
	cod_gestiune=isnull(@document.value('(/row/row/@contgestprim)[1]', 'char(13)'), ''))
	begin
		raiserror('Gestiunea primitoare nu exista sau nu este de tip I-Imobilizari!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 --and isnull(@document.value('(/row/row/@lm)[1]', 'char(9)'), '') = ''
	and @tip in ('MI') and (not exists (select 1 from lm where 
	cod=isnull(@document.value('(/row/row/@lm)[1]', 'char(9)'), '') and nivel in (select 
	strlm.nivel from strlm where mijloace_fixe=1))
	/*or dbo.f_areLMFiltru(@userASiS)=1 and isnull(@document.value('(/row/row/@lm)[1]', 'char(9)'), '') 
	not in (select cod from LMfiltrare where utilizator=@userASiS)*/)
	begin
		raiserror('Loc de munca inexistent sau nevalidat pt. mijloace fixe in tabela strlm!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 --and isnull(@document.value('(/row/row/@contlmprim)[1]', 'char(13)'), '') = ''
	and @tip in ('MT') and not exists (select 1 from lm where 
	cod=isnull(@document.value('(/row/row/@contlmprim)[1]', 'char(13)'), '') and nivel in (select 
	strlm.nivel from strlm where mijloace_fixe=1))
	begin
		raiserror('Loc de munca primitor inexistent sau nevalidat pt. mijloace fixe in tabela strlm!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 --and @contmf = ''
	and @tip='MI' --not in ('MT','MS','MR','MC','MB')
	and not exists (select 1 from conturi where cont=@contmf and are_analitice=0)
	begin
		raiserror('Cont mijloc fix inexistent sau cu analitice!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 /*and (@tip<>'MT' or @contcor <> '')
	and @tip not in ('MS','MR','MC','MB') and right(@tip,1)+@subtip not in ('MTP'/*,'MMF','MTO'*/)*/
	and left(@contmf,1)='8' and @contcor<>'' and left(@contcor,1)<>'8'
	begin
		raiserror('Contul corespondent nu trebuie completat sau trebuie sa fie de clasa 8 pt. m.f. cu cont de clasa 8!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and (@tip<>'MT' or @contcor <> '')
	and @tip not in ('MS','MR','MC','MB') and right(@tip,1)+@subtip not in ('MTP','MMF','MTO')
	and (left(@contmf,1)<>'8' or @contcor<>'') and not exists (select 1 from conturi where 
	cont=@contcor and are_analitice=0)
	begin
		raiserror('Cont corespondent inexistent sau cu analitice!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 --and isnull(@document.value('(/row/row/@contamcomprim)[1]', 'char(13)'), '') = ''
	and (@tip='MI' or @tip='MM' and @subtip='MF') and not exists (select 1 from conturi where 
	cont=isnull(@document.value('(/row/row/@contamcomprim)[1]', 'char(13)'), '') and are_analitice=0)
	begin
		raiserror('Cont amortizare inexistent sau cu analitice!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 --and isnull(@document.value('(/row/row/@conttva)[1]', 'char(13)'), '') = ''
	and isnull(@document.value('(/row/row/@sumatva)[1]', 'float'), 0) <> 0
	and @tip in ('MI')
	and @subtip in ('AF')
	and not exists (select 1 from conturi where 
	cont=isnull(@document.value('(/row/row/@conttva)[1]', 'char(13)'), '') and are_analitice=0)
	begin
		raiserror('Cont TVA inexistent sau cu analitice!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@update)[1]', 'int'), 0)=1
	and isnull(@document.value('(/row/row/@contlmprim)[1]', 'char(13)'), '') <> 
	isnull(@document.value('(/row/row/@o_contlmprim)[1]', 'char(13)'), '') 
	and @tip='MM' and @subtip='RE' 
	begin
		raiserror('Tipul reevaluarii nu se poate schimba!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@update)[1]', 'int'), 0)=1
	and @tip='MI' and @subtip='AF' and isnull(@document.value('(/row/row/@o_tiptva)[1]', 'float'), 0)=3
	and isnull(@document.value('(/row/row/@tiptva)[1]', 'float'), 0) <> 
	isnull(@document.value('(/row/row/@o_tiptva)[1]', 'float'), 0) 
	begin
		raiserror('Tip TVA nu se poate schimba in acest caz!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 --and isnull(@document.value('(/row/row/@update)[1]', 'int'), 0)=1
	and @tip='MI' and @subtip='AF' and isnull(@document.value('(/row/row/@tiptva)[1]', 'float'), 0)=3
	and left(isnull(@document.value('(/row/row/@cod)[1]', 'char(20)'), ''),1)>'S'
	begin
		raiserror('La TVA semideductibil, codul din nomenclator nu poate incepe cu litera T sau cu o litera ulterioara din alfabet!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 --and isnull(@document.value('(/row/row/@contcor)[1]', 'char(13)'), '') = ''
	and right(@tip,1)+@subtip in ('MTO') and not exists (select 1 from fisamf where 
	data_lunii_operatiei=@datal and numar_de_inventar=@nrinv and felul_operatiei='1')
	begin
		raiserror('Dati calcule lunare la acest mijloc fix si introduceti apoi doc.!',11,1)
		return -1
	end
	
	if @document.exist('/row/row')=1 --and isnull(@document.value('(/row/row/@contcor)[1]', 'char(13)'), '') = ''
	and right(@tip,1)+@subtip in ('MTO') and not exists (select 1 from fisamf where 
	data_lunii_operatiei=@datal and numar_de_inventar=@nrinv and felul_operatiei='1' 
	and convert(decimal(14,2),valoare_de_inventar)= convert(decimal(14,2),valoare_amortizata))
	begin
		raiserror('Un mijloc fix se poate trece la obiecte de inventar doar din luna urmatoare lunii in care se amortizeaza integral!',11,1)
		return -1
	end
	
end
