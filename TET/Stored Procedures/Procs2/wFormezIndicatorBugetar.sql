--***
create procedure wFormezIndicatorBugetar @cont char(40),@lm char(9),@indbug varchar(20) output
as
begin
 declare @indbug_lm varchar(20),@indbug_cont varchar(20)
 set @indbug_lm=isnull((select substring(comanda,21,20) from speciflm where loc_de_munca=@lm),'')
 set @indbug_cont=isnull((select cont_strain from contcor where contCG=@cont),'')
 set @indbug=case when @indbug_cont='' then ''
                  else ltrim(rtrim(@indbug_lm))+substring(ltrim(rtrim(@indbug_cont)),len(rtrim(ltrim(@indbug_lm)))+1,20)  end
		    
end
