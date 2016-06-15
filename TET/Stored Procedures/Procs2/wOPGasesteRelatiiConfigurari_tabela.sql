--***
create procedure wOPGasesteRelatiiConfigurari_tabela @sesiune varchar(50), @parXML xml
as
if object_id('tempdb..#tipuri') is null
	create table #tipuri(meniu varchar(20))
alter table #tipuri add tip varchar(20), subtip varchar(20), tabela varchar(200), denumire varchar(2000),
	alte_machete int default 0 --> alte_machete=nr de configurari diferite care refera linia curenta exceptand cele care se afla deja in tabela #tipuri
--test select * from #tipuri
/*
--> campul tabela:	webconfigmeniu
					webconfigtipuri
					webconfigtipuri_tab	--> configurari a caror singura legatura cu "meniu+/tip+/subtip" are loc prin webconfigtaburi (daca ar fi prin tipuri ar aparea la webconfigtipuri)
					webconfigtipuri_reftab	--> configurari proprii id-ului "meniu+/tip+/subtip" care sunt folosite, referite in tab-urile altor configurari
*/
