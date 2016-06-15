--***
create procedure [dbo].[yso_wOPRefacACTE_p] @sesiune varchar(50), @parXML xml 
as  
    declare @datajos datetime ,@datasus datetime, @listaGestiuni varchar(max),
    @Subunitate varchar(1),@Tip varchar(2),@Numar varchar(10),@Cod varchar(10),@Data datetime ,
    @Gestiune varchar(10),@GestPV varchar(10),@Cantitate float ,@Pret_valuta float ,@Pret_de_stoc float,@stergere bit,
    @generare bit,@databon datetime ,@casabon varchar(10),@numarbon int ,@UID varchar(50),@userASiS varchar(50), @msgEroare varchar(max)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
set @GestPV=isnull((select dbo.wfProprietateUtilizator('GESTPV', @userASiS )),'')

select	@datajos=isnull(@parXML.value('(/*/@datajos)[1]','datetime'),'01/01/1901'),
		@datasus=isnull(@parXML.value('(/*/@datasus)[1]','datetime'),'01/01/1901'),
		@gestiune =isnull(@parXML.value('(/*/@gestiune)[1]','varchar(10)'),@GestPV),
		@stergere=isnull(@parXML.value('(/*/@stergere)[1]','bit'),0),
		@generare=isnull(@parXML.value('(/*/@generare)[1]','bit'),0)

--select '01/01/1901' datajos, '05/02/2099' datasus, 'bla' gestiune, 1 stergere, 0 generare
select @Gestiune gestiune, 1 stergere, 1 generare
for xml raw