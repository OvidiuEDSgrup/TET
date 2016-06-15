--***
create procedure yso_wOPSchimbStare @sesiune varchar(50), @parXML xml 
as     
begin try 
declare @schimbstare varchar(1),@subtip varchar(2),@numar varchar(20),@codMeniu varchar(2),@tip varchar(2),@tert varchar(13),@contractcor varchar(20),
		@stare int ,@termen varchar(20), @stareold int,@definitivare int, @datadoc datetime
declare @iDoc int 

/*sp
declare @procid int=@@procid, @objname sysname
set @objname=object_name(@procid)
EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
--sp*/

EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

select @numar=numar ,@codMeniu=codMeniu ,@tip=tip, @tert=tert ,@schimbstare=stare,@contractcor=contractcor ,@termen=termen,@definitivare=definitivare,
	   @datadoc=datadoc
from OPENXML(@iDoc, '/parametri')
WITH 
(
		numar varchar(20)'./@numar',
		Stare varchar(1)'./@stare',
		codMeniu varchar(2)'./@codMeniu',
		tert varchar(13)'./@tert',
		tip varchar(2)'./@tip',
		contractcor varchar(20)'./@contractcor',
		termen	varchar(20)'./@termen',
		datadoc datetime'./@data',
		definitivare varchar(1)'./@definitivare'
)

if @tip in ('BF','BK','FA','FC','BP')
	 begin
		 set @schimbstare=SUBSTRING(@schimbstare,1,1)
			 if @schimbstare is null or @schimbstare=''
				 begin
					raiserror ('Stare necompletata',11,1)
				 end
		 set @stareold=isnull((select stare from con where Contract=@numar and Tert=@tert and Termen=@termen and Tip=@tip),0)
			if @tip in (
/*startsp
				'BK','FC',
--stopsp*/
				'BP') and @schimbstare<@stareold --and @stareold>1
				 begin
				  raiserror('Nu se poate face trecerea in stare inferioara',11,1)
				  return -1
				 end
--/*startsp
			if @tip in ('BK','FC') and @schimbstare in ('4','6') --and @stareold>1
				 begin
				  raiserror('Nu se poate face trecerea in aceasta stare',11,1)
				  return -1
				 end
				 
			if @tip in ('BK','FC') and @stareold in ('4','6') --and @stareold>1
				 begin
				  raiserror('Nu se poate face trecerea din aceasta stare',11,1)
				  return -1
				 end
--stopsp*/
		--if @schimbstare <>1 and @schimbstare <>0
			-- begin
			  --raiserror('Nu se poate face trecerea in aceasta stare ',11,1)
			-- -- return -1
			-- end
		 
	 update con set Stare=@schimbstare where Contract=@numar and Tert=@tert and Termen=@termen and Tip=@tip
 end
 else 
 if @tip in ('AP','TE')
begin
	 set @stareold=isnull((select max(stare) from doc where Tip=@tip and Numar=@numar and Cod_tert=@tert and data=@datadoc),0)
	 if @definitivare=0
  		select 'Bifati "definitivare " pentru ca documentul sa fie schimbat in starea 2-Definitiv!' as textMesaj for xml raw, root('Mesaje')
	  if @stareold='2'
		select 'Documentul este deja in stare 2-Definitiv!' as textMesaj for xml raw, root('Mesaje') 	
	  if @definitivare=1
		update doc set Stare='2' where Tip=@tip and Numar=@numar and Cod_tert=@tert and	data=@datadoc
		update pozdoc set Stare='2' where Tip=@tip and Numar=@numar and	data=@datadoc
end
 exec sp_xml_removedocument @iDoc 
-- select * from pozdoc
end try
begin catch
declare @eroare varchar(200) 
	set @eroare='(yso_wOPSchimbStare)'+ERROR_MESSAGE()
	raiserror(@eroare, 11, 1) 
end catch