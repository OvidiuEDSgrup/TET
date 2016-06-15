--***
/* Procedura apartine machetelor de configurare Buget, scrie valori previzionate in EXPVAL*/

CREATE procedure  wScriuDateBuget  @sesiune varchar(50), @parXML XML
as
declare @cod varchar(10), @lm varchar(13),@can varchar(4),@nan int,@datajos datetime,@datasus datetime
declare @p01 float,@p02 float,@p03 float,@p04 float,@p05 float,@p06 float,@p07 float,@p08 float,@p09 float,
@p10 float,@p11 float,@p12 float

set @cod = rtrim(isnull(@parXML.value('(/row/row/@cod_indicator)[1]', 'varchar(20)'), ''))
set @lm=rtrim(isnull(@parXML.value('(/row/@lm)[1]', 'varchar(20)'), ''))
set @can= isnull(@parXML.value('(/row/@an)[1]', 'int'), 1)	

if ISNUMERIC(@can)=1 and CONVERT(int,@can)>1920
	set @nan=CONVERT(int,@can)
else
	set @nan=YEAR(getdate())
	
set @datajos='01/01/'+LTRIM(str(@nan))
set @datasus='12/31/'+LTRIM(str(@nan))
set @p01=rtrim(isnull(@parXML.value('(/row/row/@l01)[1]', 'float'), ''))
set @p02=rtrim(isnull(@parXML.value('(/row/row/@l02)[1]', 'float'), ''))
set @p03=rtrim(isnull(@parXML.value('(/row/row/@l03)[1]', 'float'), ''))
set @p04=rtrim(isnull(@parXML.value('(/row/row/@l04)[1]', 'float'), ''))
set @p05=rtrim(isnull(@parXML.value('(/row/row/@l05)[1]', 'float'), ''))
set @p06=rtrim(isnull(@parXML.value('(/row/row/@l06)[1]', 'float'), ''))
set @p07=rtrim(isnull(@parXML.value('(/row/row/@l07)[1]', 'float'), ''))
set @p08=rtrim(isnull(@parXML.value('(/row/row/@l08)[1]', 'float'), ''))
set @p09=rtrim(isnull(@parXML.value('(/row/row/@l09)[1]', 'float'), ''))
set @p10=rtrim(isnull(@parXML.value('(/row/row/@l10)[1]', 'float'), ''))
set @p11=rtrim(isnull(@parXML.value('(/row/row/@l11)[1]', 'float'), ''))
set @p12=rtrim(isnull(@parXML.value('(/row/row/@l12)[1]', 'float'), ''))

delete from Expval where
Cod_indicator=@cod and Element_1=@lm and tip='P'
and data between @datajos and @datasus

--Se face insertul cu o zi dupa pentru ca nu stim exact ultima zi din luna
--si facem prin scadere
insert into Expval(Cod_indicator,Tip,Data,Element_1,Element_2,Element_3,Element_4,Element_5,Valoare)
select @cod,'P',dateadd(day,-1,'02/01/'+ltrim(str(@nan))),@lm,'','','','',@p01
union  all
select @cod,'P',dateadd(day,-1,'03/01/'+ltrim(str(@nan))),@lm,'','','','',@p02
union  all
select @cod,'P',dateadd(day,-1,'04/01/'+ltrim(str(@nan))),@lm,'','','','',@p03
union  all
select @cod,'P',dateadd(day,-1,'05/01/'+ltrim(str(@nan))),@lm,'','','','',@p04
union  all
select @cod,'P',dateadd(day,-1,'06/01/'+ltrim(str(@nan))),@lm,'','','','',@p05
union  all
select @cod,'P',dateadd(day,-1,'07/01/'+ltrim(str(@nan))),@lm,'','','','',@p06
union  all
select @cod,'P',dateadd(day,-1,'08/01/'+ltrim(str(@nan))),@lm,'','','','',@p07
union  all
select @cod,'P',dateadd(day,-1,'09/01/'+ltrim(str(@nan))),@lm,'','','','',@p08
union  all
select @cod,'P',dateadd(day,-1,'10/01/'+ltrim(str(@nan))),@lm,'','','','',@p09
union  all
select @cod,'P',dateadd(day,-1,'11/01/'+ltrim(str(@nan))),@lm,'','','','',@p10
union  all
select @cod,'P',dateadd(day,-1,'12/01/'+ltrim(str(@nan))),@lm,'','','','',@p11
union  all --exceptie face ultima zi din an care este intotdeauna 31.Decembrie
select @cod,'P','12/31/'+ltrim(str(@nan)),@lm,'','','','',@p12

exec wIaDateBuget '',@parXML
