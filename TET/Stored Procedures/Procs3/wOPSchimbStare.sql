--***
create procedure wOPSchimbStare @sesiune varchar(50), @parXML xml 
as     
begin try 
	declare @schimbstare varchar(1),@subtip varchar(2),@numar varchar(20),@codMeniu varchar(2),@tip varchar(2),@tert varchar(13),@contractcor varchar(20),
			@stare int ,@termen varchar(20), @stareold int,@definitivare int, @datadoc datetime
	declare @iDoc int ,@sub varchar(9)

	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	select	@sub=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else @sub end)
	from par
	where (Tip_parametru='GE' and Parametru ='SUBPRO')

	select @numar=numar ,@codMeniu=codMeniu ,@tip=tip, @subtip=subtip, @tert=tert ,@schimbstare=stare,@contractcor=contractcor ,@termen=termen,@definitivare=definitivare,
		   @datadoc=datadoc
	from OPENXML(@iDoc, '/parametri')
	WITH 
	(
			numar varchar(20)'./@numar',
			Stare varchar(1)'./@stare',
			codMeniu varchar(2)'./@codMeniu',
			tert varchar(13)'./@tert',
			tip varchar(2)'./@tip',
			subtip varchar(2)'./@subtip',
			contractcor varchar(20)'./@contractcor',
			termen	varchar(20)'./@termen',
			datadoc datetime'./@data',
			definitivare varchar(1)'./@definitivare'
	)

	select @numar,@codMeniu,@tip,@subtip,@tert,@schimbstare,@contractcor,@termen,@definitivare

	if @tip in ('BF','BK','FA','FC','BP')
	 begin
		set @schimbstare=SUBSTRING(@schimbstare,1,1)
		
		if @tip in ('BK','FC') and @subtip='DC' and @definitivare=1--pentru BK si FC se poate folosi si operatia de definitivare
		begin	
			set @schimbstare='1'
			select @schimbstare
		end
			
		if @schimbstare is null or @schimbstare=''
		begin
			raiserror ('(wOPSchimbStare)Stare necompletata',11,1)
		end
		
		set @stareold=isnull((select stare from con where Subunitate=@sub and Tip=@tip and data=@datadoc and Contract=@numar and Tert=@tert),0)
		
		update con set Stare=@schimbstare where Subunitate=@sub and Tip=@tip and data=@datadoc and Contract=@numar and Tert=@tert and Termen=@termen 
		
		if @schimbstare =1
			select 'Comanda/Contractul dvs cu numarul:'+@numar+' a fost definitivat(a)!' as textMesaj, 'Atentie' as titluMesaj for xml raw, root('Mesaje')
	end
	
	else 
	if @tip in ('AP','TE')
	begin
		set @stareold=isnull((select max(stare) from doc where Tip=@tip and Numar=@numar and Cod_tert=@tert and data=@datadoc),0)
		if @definitivare=0
			select '(wOPSchimbStare)Bifati "definitivare " pentru ca documentul sa fie schimbat in starea 2-Definitiv!' as textMesaj for xml raw, root('Mesaje')
		
		if @stareold='2'
			select '(wOPSchimbStare)Documentul este deja in stare 2-Definitiv!' as textMesaj for xml raw, root('Mesaje') 	
		
		if @definitivare=1
		begin
			update doc set Stare='2' where Tip=@tip and Numar=@numar and Cod_tert=@tert and	data=@datadoc
			update pozdoc set Stare='2' where Tip=@tip and Numar=@numar and	data=@datadoc
		end
	end
	 exec sp_xml_removedocument @iDoc 
	-- select * from pozdoc
end try
begin catch
declare @eroare varchar(200) 
	set @eroare='(wOPSchimbStare) '+ERROR_MESSAGE()
	raiserror(@eroare, 11, 1) 
end catch
