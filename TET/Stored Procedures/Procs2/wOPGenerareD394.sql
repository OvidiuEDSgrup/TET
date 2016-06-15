﻿--***
Create procedure wOPGenerareD394 @sesiune varchar(50), @parXML xml
as

declare @codfiscal varchar(20), @tipdecl varchar(1), @numedecl varchar(150), @prendecl varchar(50), 
	@functiedecl varchar(50), --@lm char(9), @inXML int, 
	@calefisier varchar(300), @data datetime, @lunaalfa varchar(15), @luna int, @an int, --@dataj datetime, @datas datetime, 
	@userASiS varchar(10), @nrLMFiltru int, @LMFiltru varchar(9)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenerareD394'

--exec luare_date_par 'GE', 'CODFISC', 0, 0, @codfiscal output
--set @codfiscal=Replace (Replace (Replace (upper(@codfiscal),'RO',''),'R',''),' ','')
set @tipdecl = ISNULL(@parXML.value('(/parametri/@tipdecl)[1]', 'varchar(1)'), '')
set @numedecl = ISNULL(@parXML.value('(/parametri/@numedecl)[1]', 'varchar(150)'), '')
set @prendecl = ISNULL(@parXML.value('(/parametri/@prendecl)[1]', 'varchar(50)'), '')
set @functiedecl = ISNULL(@parXML.value('(/parametri/@functiedecl)[1]', 'varchar(50)'), '')
/*exec luare_date_par 'GE', 'NDECLTVA', 0, 0, @numedecl output
set @prendecl=right(@numedecl,len(@numedecl)-CHARINDEX(' ',@numedecl))
set @numedecl=LEFT(@numedecl,CHARINDEX(' ',@numedecl)-1)
exec luare_date_par 'GE', 'FDECLTVA', 0, 0, @functiedecl output
exec luare_date_par 'GE', 'CFDECLTVA', 0, 0, @calefisier output*/
exec luare_date_par 'AR', 'CALEFORM', 0, 0, @calefisier output
select @calefisier=rtrim(@calefisier)
/*set @calefisier=rTrim (@calefisier)+(case when rTrim (@calefisier)<>'' AND 
	Right (rTrim (@calefisier),1)<>'\' then '\' else '' end)+'394_'+@tipdecl+'_D'+rTrim(Str(@luna,2))+
	Right(Str(@an,4),2)+'_J'+rTrim (@codfiscal)+'.xml'*/
--set @data = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '01/01/1901')
set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
if @luna<>0 and @an<>0
begin
	set @data=dbo.bom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
	set @data=(case @tipdecl when 'T' then Dateadd(MONTH,-(Month(@data)-1) % 3,@data) when 'S' then 
		Dateadd(month,-(Month(@data)-1) % 6,@data) when 'A' then Dateadd(month,1-Month(@data),@data) 
		else @data end)
end
select @lunaalfa=LunaAlfa from fCalendar(@data,@data)
select @nrLMFiltru=count(1), @LMFiltru=isnull(max(Cod),'') from LMfiltrare where utilizator=@userASiS

begin try  
	/*if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>0
		raiserror('Nu puteti efectua operatia fiindca aveti drepturi de acces doar pe anumite locuri de munca!' ,16,1)
	*/		
	if @luna=0 or @an=0
		raiserror('Alegeti luna si anul!' ,16,1)
			
	if rtrim(left(@calefisier,4))='' --'\394'
		raiserror('Completati cale fisier in parametri!' ,16,1)
			
	if @numedecl='' or @prendecl='' or @functiedecl=''
		raiserror('Completati nume, prenume si functie declarant!' ,16,1)
	
	exec Declaratia394 @data=@data, @nume_declar=@numedecl, @prenume_declar=@prendecl, 
		@functie_declar=@functiedecl, @caleFisier=@calefisier, @dinRia=1, @tip_D394=@tipdecl

	select @numedecl=rtrim(@numedecl)+' '+@prendecl--, @calefisier=LEFT(@calefisier,CHARINDEX('394',@calefisier)-1)
	exec setare_par 'GE', 'NDECLTVA', 'Nume pers. declaratie TVA', 0, 0, @numedecl
	exec setare_par 'GE', 'FDECLTVA', 'Functie pers. declaratie TVA', 0, 0, @functiedecl
	--exec setare_par 'GE', 'CFDECLTVA', 'Cale fisier declaratie TVA', 0, 0, @calefisier

	select 'Terminat operatia'+/*rtrim(@lunaalfa)+' anul '+convert(char(4),year(@datas))+*/'!' 
		as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch 
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()+' (wOPGenerareD394)'
	raiserror(@eroare, 16, 1) 
end catch
