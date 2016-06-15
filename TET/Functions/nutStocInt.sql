--***
create function nutStocInt (@laData datetime,@vGestiune char(13),@vCod char(20),@vCont varchar(40),@vCodISO char(13))
returns @retTab table(Gestiune char(13),Cod char(20),Cont varchar(40),CodISO char(13),Cantitate float,Valoare float)
as 
begin

declare @vDataInc datetime,@vDataImp datetime
set @vDataInc = ltrim((select isnull(str(val_numerica),'1901') from par where tip_parametru='GE' and parametru='ANULINC'))+'-'+ltrim((select replace(isnull(str(val_numerica,2),' 1'),' ','0') from par where tip_parametru='GE' and parametru='LUNAINC'))+'-01'
set @vDataImp = ltrim((select isnull(str(val_numerica),'1901') from par where tip_parametru='GE' and parametru='ANULIMPL'))+'-'+ltrim((select replace(isnull(str(val_numerica,2),' 1'),' ','0') from par where tip_parametru='GE' and parametru='LUNAIMPL'))+'-01'
set @vDataInc=dbo.eom(@vDataInc)
set @vDataImp=dbo.eom(@vDataImp)


--if @laData < @vDataImp SI=0
if @laData between @vdataImp and @vdataInc
   begin
     insert @retTab
     select i.cod_gestiune as Gestiune,i.cod as Cod,i.cont as Cont,i.cod_intrare as CodISO,sum(i.stoc) as Cantitate,sum(i.stoc * i.pret_cu_amanuntul) as Valoare_stoc 
            from istoricstocuri i
            where i.data_lunii = @vDataImp and i.cod_gestiune=(case @vGestiune when '' then i.cod_gestiune else @vGestiune end) and i.cod=(case @vCod when '' then i.cod else @vCod end) and i.cont=(case @vCont when '' then i.cont else @vCont end) and i.cod_intrare=(case @vCodISO when '' then i.cod_intrare else @vCodISO end) 
            group by i.cod_gestiune,i.cod,i.cont,i.cod_intrare
     union all
     select p.gestiune,p.cod,p.cont_de_stoc,p.cod_intrare,sum((case p.tip_miscare when 'E' then -p.cantitate else p.cantitate end)),sum((case p.tip_miscare when 'E' then -(p.cantitate * p.pret_de_stoc) else (p.cantitate * p.pret_de_stoc) end))
            from pozdoc p
            where p.data between (@laData-day(@laData)+1)and @laData and tip_miscare in ('I','E') and p.gestiune=(case @vGestiune when '' then p.gestiune else @vGestiune end) and p.cod=(case @vCod when '' then p.cod else @vCod end) and p.cont_de_stoc=(case @vCont when '' then p.cont_de_stoc else @vCont end) and p.cod_intrare=(case @vCodISO when '' then p.cod_intrare else @vCodISO end) 
            group by p.gestiune,p.cod,p.cont_de_stoc,p.cod_intrare
     union all
     select p.gestiune_primitoare,p.cod,p.cont_corespondent,p.cod_intrare,sum(p.cantitate),sum(p.cantitate * p.pret_de_stoc) 
            from pozdoc p
            where p.data between (@laData-day(@laData)+1)and @laData and p.tip='TE' and p.gestiune_primitoare=(case @vGestiune when '' then p.gestiune_primitoare else @vGestiune end) and p.cod=(case @vCod when '' then p.cod else @vCod end) and p.cont_de_stoc=(case @vCont when '' then p.cont_de_stoc else @vCont end) and p.cod_intrare=(case @vCodISO when '' then p.cod_intrare else @vCodISO end) 
            group by p.gestiune_primitoare,p.cod,p.cont_corespondent,p.cod_intrare
   end
   else    
     if @laData > @vdataInc
        begin
          insert @retTab
          select i.cod_gestiune as Gestiune,i.cod as Cod,i.cont as Cont,i.cod_intrare as CodISO,sum(i.stoc_initial) as Cantitate,sum(i.stoc_initial * i.pret_cu_amanuntul) as Valoare_stoc
            from stocuri i
            where i.cod_gestiune=(case @vGestiune when '' then i.cod_gestiune else @vGestiune end) and i.cod=(case @vCod when '' then i.cod else @vCod end) and i.cont=(case @vCont when '' then i.cont else @vCont end) and i.cod_intrare=(case @vCodISO when '' then i.cod_intrare else @vCodISO end)  
            group by i.cod_gestiune,i.cod,i.cont,i.cod_intrare
          union all
          select p.gestiune,p.cod,p.cont_de_stoc,p.cod_intrare,sum((case p.tip_miscare when 'E' then -p.cantitate else p.cantitate end)),sum((case p.tip_miscare when 'E' then -(p.cantitate * p.pret_de_stoc) else (p.cantitate * p.pret_de_stoc) end))
            from pozdoc p
            where p.data between (@vDataInc+1) and @laData and tip_miscare in ('I','E') and p.gestiune=(case @vGestiune when '' then p.gestiune else @vGestiune end) and p.cod=(case @vCod when '' then p.cod else @vCod end) and p.cont_de_stoc=(case @vCont when '' then p.cont_de_stoc else @vCont end) and p.cod_intrare=(case @vCodISO when '' then p.cod_intrare else @vCodISO end) 
            group by p.gestiune,p.cod,p.cont_de_stoc,p.cod_intrare
          union all
          select p.gestiune_primitoare,p.cod,p.cont_corespondent,p.cod_intrare,sum(p.cantitate),sum(p.cantitate * p.pret_de_stoc) 
            from pozdoc p
            where p.data between (@vDataInc+1) and @laData and p.tip='TE' and p.gestiune_primitoare=(case @vGestiune when '' then p.gestiune_primitoare else @vGestiune end) and p.cod=(case @vCod when '' then p.cod else @vCod end) and p.cont_de_stoc=(case @vCont when '' then p.cont_de_stoc else @vCont end) and p.cod_intrare=(case @vCodISO when '' then p.cod_intrare else @vCodISO end) 
            group by p.gestiune_primitoare,p.cod,p.cont_corespondent,p.cod_intrare
   end 
   return 
end
