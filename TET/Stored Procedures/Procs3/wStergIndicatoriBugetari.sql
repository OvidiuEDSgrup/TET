create procedure  [dbo].[wStergIndicatoriBugetari] @sesiune varchar(50), @parXML xml
as
	DECLARE @indbug varchar(20)       
        
     select
         @indbug = @parXML.value('(/row/@indbug)[1]','varchar(20)')         

declare @mesajeroare varchar(500)
set @mesajeroare=''
select @mesajeroare=
      case when exists (select 1 from angbug a where a.indicator=@indbug) then 'Nu se poate sterge un indicator bugetar pe baza caruia s-au facut angajamente bugetare!!' 
           when exists (select 1 from pozncon p where substring (p.numar,1,7)='BA_TRIM' 
                           and substring(p.comanda,21,20)=@indbug) then 'Nu se poate sterge un indicator bugetar care are alocat buget!!'
      else ''  end

if @mesajeroare=''
	delete from indbug where indbug=@indbug
else 
	raiserror(@mesajeroare, 11, 1)
