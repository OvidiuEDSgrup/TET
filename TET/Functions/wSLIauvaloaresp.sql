--***
create function wSLIauvaloaresp (@data datetime,@marca varchar(6),@loc_de_munca varchar(9),@subtip varchar(2),@numar_curent int)
returns float
as
begin
declare @data1 datetime,@data2 datetime,@ore float,@tore float,@val float,@valind float,@valret float,@oresupl float,
@ore1 float,@tore1 float,@val1 float,@ore2 float,@tore2 float,@val2 float,
@ore3 float,@tore3 float,@val3 float,@ore4 float,@tore4 float,@val4 float,
@ore5 float,@tore5 float,@val5 float,@ore6 float,@tore6 float,@val6 float,
@ore7 float,@tore7 float,@val7 float,@ore8 float,@tore8 float,@val8 float
set @data1=dbo.bom(@data) 
set @data2=dbo.eom(@data)
set @valret=0

declare @scond1 int,@sc1suma int,@scond2 int,@sc2suma int,@scond3 int,@sc3suma int,
@scond4 int,@sc4suma int,@scond5 int,@sc5suma int,@scond6 int,@sc6suma int,@scpeste int
set @scond1=dbo.iauParL('PS','SCOND1')
set @sc1suma=dbo.iauParL('PS','SC1-SUMA')
set @scond2=dbo.iauParL('PS','SCOND2')
set @sc2suma=dbo.iauParL('PS','SC2-SUMA')
set @scond3=dbo.iauParL('PS','SCOND3')
set @sc3suma=dbo.iauParL('PS','SC3-SUMA')
set @scond4=dbo.iauParL('PS','SCOND4')
set @sc4suma=dbo.iauParL('PS','SC4-SUMA')
set @scond5=dbo.iauParL('PS','SCOND5')
set @sc5suma=dbo.iauParL('PS','SC5-SUMA')
set @scond6=dbo.iauParL('PS','SCOND6')
set @sc6suma=dbo.iauParL('PS','SC6-SUMA')
set @scpeste=dbo.iauParL('PS','SP-PR-ORE')

select @ore1=(case when @scond1=1 then ore__cond_1 else ore_regie+ore_acord end),@val1=spor_conditii_1 from pontaj where data=@data and marca=@marca and loc_de_munca=@loc_de_munca and numar_curent=@numar_curent and spor_conditii_1>0
select @tore1=sum((case when @scond1=1 then ore__cond_1 else ore_regie+ore_acord end)) from pontaj where data between @data1 and @data2 and marca=@marca and loc_de_munca=@loc_de_munca and spor_conditii_1>0
select @val1=(case when @sc1suma=1 then @val1 else spor_cond_1 end) from brut where data=@data2 and marca=@marca and loc_de_munca=@loc_de_munca

select @ore2=(case when @scond2=1 then ore__cond_2 else ore_regie+ore_acord end),@val2=spor_conditii_2 from pontaj where data=@data and marca=@marca and loc_de_munca=@loc_de_munca and numar_curent=@numar_curent and spor_conditii_2>0
select @tore2=sum((case when @scond2=1 then ore__cond_2 else ore_regie+ore_acord end)) from pontaj where data between @data1 and @data2 and marca=@marca and loc_de_munca=@loc_de_munca and spor_conditii_2>0
select @val2=(case when @sc2suma=1 then @val2 else spor_cond_2 end) from brut where data=@data2 and marca=@marca and loc_de_munca=@loc_de_munca

select @ore3=(case when @scond3=1 then ore__cond_3 else ore_regie+ore_acord end),@val3=spor_conditii_3 from pontaj where data=@data and marca=@marca and loc_de_munca=@loc_de_munca and numar_curent=@numar_curent and spor_conditii_3>0
select @tore3=sum((case when @scond3=1 then ore__cond_3 else ore_regie+ore_acord end)) from pontaj where data between @data1 and @data2 and marca=@marca and loc_de_munca=@loc_de_munca and spor_conditii_3>0
select @val3=(case when @sc3suma=1 then @val3 else spor_cond_3 end) from brut where data=@data2 and marca=@marca and loc_de_munca=@loc_de_munca

select @ore4=(case when @scond4=1 then ore__cond_4 else ore_regie+ore_acord end),@val4=spor_conditii_4 from pontaj where data=@data and marca=@marca and loc_de_munca=@loc_de_munca and numar_curent=@numar_curent and spor_conditii_4>0
select @tore4=sum((case when @scond4=1 then ore__cond_4 else ore_regie+ore_acord end)) from pontaj where data between @data1 and @data2 and marca=@marca and loc_de_munca=@loc_de_munca and spor_conditii_4>0
select @val4=(case when @sc4suma=1 then @val4 else spor_cond_4 end) from brut where data=@data2 and marca=@marca and loc_de_munca=@loc_de_munca

select @ore5=(case when @scond5=1 then ore__cond_5 else ore_regie+ore_acord end),@val5=spor_conditii_5 from pontaj where data=@data and marca=@marca and loc_de_munca=@loc_de_munca and numar_curent=@numar_curent and spor_conditii_5>0
select @tore5=sum((case when @scond5=1 then ore__cond_5 else ore_regie+ore_acord end)) from pontaj where data between @data1 and @data2 and marca=@marca and loc_de_munca=@loc_de_munca and spor_conditii_5>0
select @val5=(case when @sc5suma=1 then @val5 else spor_cond_5 end) from brut where data=@data2 and marca=@marca and loc_de_munca=@loc_de_munca

select @ore6=(case when @scond6=1 then ore_donare_sange else ore_regie+ore_acord end),@val6=spor_conditii_6 from pontaj where data=@data and marca=@marca and loc_de_munca=@loc_de_munca and numar_curent=@numar_curent and spor_conditii_6>0
select @tore6=sum((case when @scond6=1 then ore_donare_sange else ore_regie+ore_acord end)) from pontaj where data between @data1 and @data2 and marca=@marca and loc_de_munca=@loc_de_munca and spor_conditii_6>0
select @val6=(case when @sc6suma=1 then @val6 else spor_cond_6 end) from brut where data=@data2 and marca=@marca and loc_de_munca=@loc_de_munca

select @ore=ore_regie+ore_acord,@val=spor_cond_7 from pontaj where data=@data and marca=@marca and loc_de_munca=@loc_de_munca and numar_curent=@numar_curent and spor_cond_7>0
select @tore=sum(ore_regie+ore_acord) from pontaj where data between @data1 and @data2 and marca=@marca and loc_de_munca=@loc_de_munca and spor_cond_7>0
select @val=spor_cond_7,@valind=(spor_vechime+ind_nemotivate) from brut where data=@data2 and marca=@marca and loc_de_munca=@loc_de_munca

select @ore7=ore_regie+ore_acord,@val7=spor_specific from pontaj where data=@data and marca=@marca and loc_de_munca=@loc_de_munca and numar_curent=@numar_curent and spor_specific>0
select @tore7=sum(ore_regie+ore_acord) from pontaj where data between @data1 and @data2 and marca=@marca and loc_de_munca=@loc_de_munca and spor_specific>0
select @val7=spor_specific from brut where data=@data2 and marca=@marca and loc_de_munca=@loc_de_munca

select @ore8=(case when @scpeste=1 then ore_sistematic_peste_program else ore_lucrate end),@val8=sistematic_peste_program from pontaj where data=@data and marca=@marca and loc_de_munca=@loc_de_munca and numar_curent=@numar_curent and sistematic_peste_program>0
select @tore8=sum((case when @scpeste=1 then ore_sistematic_peste_program else ore_lucrate end)) from pontaj where data between @data1 and @data2 and marca=@marca and loc_de_munca=@loc_de_munca and sistematic_peste_program>0
select @val8=spor_sistematic_peste_program from brut where data=@data2 and marca=@marca and loc_de_munca=@loc_de_munca

set @valret=(case when @sc1suma=1 then isnull(@val1,0) else (case when isnull(@tore1,0)=0 then 0 else round((isnull(@val1,0)*isnull(@ore1,0))/@tore1,2) end) end)+
(case when @sc2suma=1 then isnull(@val2,0) else (case when isnull(@tore2,0)=0 then 0 else round((isnull(@val2,0)*isnull(@ore2,0))/@tore2,2) end) end)+
(case when @sc3suma=1 then isnull(@val3,0) else (case when isnull(@tore3,0)=0 then 0 else round((isnull(@val3,0)*isnull(@ore3,0))/@tore3,2) end) end)+
(case when @sc4suma=1 then isnull(@val4,0) else (case when isnull(@tore4,0)=0 then 0 else round((isnull(@val4,0)*isnull(@ore4,0))/@tore4,2) end) end)+
(case when @sc5suma=1 then isnull(@val5,0) else (case when isnull(@tore5,0)=0 then 0 else round((isnull(@val5,0)*isnull(@ore5,0))/@tore5,2) end) end)+
(case when @sc6suma=1 then isnull(@val6,0) else (case when isnull(@tore6,0)=0 then 0 else round((isnull(@val6,0)*isnull(@ore6,0))/@tore6,2) end) end)+
(case when isnull(@tore,0)=0 then 0 else round((isnull(@val,0)*isnull(@ore,0))/@tore,2) end)+
(case when isnull(@tore,0)=0 then 0 else round((isnull(@valind,0)*isnull(@ore,0))/@tore,2) end)+
(case when isnull(@tore7,0)=0 then 0 else round((isnull(@val7,0)*isnull(@ore7,0))/@tore7,2) end)+
(case when isnull(@tore8,0)=0 then 0 else round((isnull(@val8,0)*isnull(@ore8,0))/@tore8,2) end)
return @valret
end

