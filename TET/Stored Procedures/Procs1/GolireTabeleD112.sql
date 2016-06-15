--***
Create procedure GolireTabeleD112 @DataJ datetime, @DataS datetime
as  
Begin
	declare @utilizator varchar(20), @lm varchar(9), @multiFirma int

--	citire utilizator 
	set @utilizator = dbo.fIaUtilizator(null)
	select @lm='', @multiFirma=0
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

--	in cazul BD multifirma stabilesc locul de munca pe care lucreaza utilizatorul
	if @multiFirma=1 
		select @lm=isnull(min(Cod),'') from LMfiltrare where utilizator=@utilizator and cod in (select cod from lm where Nivel=1)

--	exec CreareTabeleD112
--	golire tabele angajator
	if exists (select * from sysobjects where name ='D112angajatorA')
		delete from D112angajatorA where data=@DataS and (@multiFirma=0 or loc_de_munca=@lm)
	if exists (select * from sysobjects where name ='D112angajatorB')
		delete from D112angajatorB where data=@DataS and (@multiFirma=0 or loc_de_munca=@lm)
	if exists (select * from sysobjects where name ='D112angajatorC5')
		delete from D112angajatorc5 where data=@DataS and (@multiFirma=0 or loc_de_munca=@lm)
	if exists (select * from sysobjects where name ='D112angajatorF2')
		delete from D112angajatorF2 where data=@DataS and (@multiFirma=0 or loc_de_munca=@lm)

--	golire tabele asigurati
	if exists (select * from sysobjects where name ='D112Asigurat')
		delete from D112Asigurat where data=@DataS and (@multiFirma=0 or loc_de_munca=@lm)
	if exists (select * from sysobjects where name ='D112coAsigurati')
		delete from D112coAsigurati where data=@DataS and (@multiFirma=0 or loc_de_munca=@lm)
	if exists (select * from sysobjects where name ='D112AsiguratA')
		delete from D112AsiguratA where data=@DataS and (@multiFirma=0 or loc_de_munca=@lm)
	if exists (select * from sysobjects where name ='D112AsiguratB1')
		delete from D112AsiguratB1 where data=@DataS and (@multiFirma=0 or loc_de_munca=@lm)
	if exists (select * from sysobjects where name ='D112AsiguratB11')
		delete from D112AsiguratB11 where data=@DataS and (@multiFirma=0 or loc_de_munca=@lm)
	if exists (select * from sysobjects where name ='D112AsiguratB234')
		delete from D112AsiguratB234 where data=@DataS and (@multiFirma=0 or loc_de_munca=@lm)
	if exists (select * from sysobjects where name ='D112AsiguratC')
		delete from D112AsiguratC where data=@DataS and (@multiFirma=0 or loc_de_munca=@lm)
	if exists (select * from sysobjects where name ='D112AsiguratD')
		delete from D112AsiguratD where data=@DataS and (@multiFirma=0 or loc_de_munca=@lm)
	if exists (select * from sysobjects where name ='D112AsiguratE3')
		delete from D112AsiguratE3 where data=@DataS and (@multiFirma=0 or loc_de_munca=@lm) and isnull(E3_4,'')<>'A'

End
