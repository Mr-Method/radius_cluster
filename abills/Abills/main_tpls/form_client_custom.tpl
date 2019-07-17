
<div class="row">
%NEWS%
</div>

<div class="row">
    <!-- Left col -->
    <section class="col-lg-8 connectedSortable">
        <!-- small box -->
        <div class="small-box bg-red">
            <div class="inner">
                <h4>Ваш депозит: %MAIN_INFO_DEPOSIT% грн</h4>
                <p>Рекомендуемая сумма для оплаты %RECOMENDED_PAY% грн</p>
                <p>Номер счета Ukrpays: %MAIN_INFO_UID%</p>
                <p>Последнее пополнение счета: &nbsp; %PAYMENTS_DATETIME% &nbsp; %PAYMENTS_SUM% грн &nbsp; %PAYMENTS_DSC%</p>
                <a href='$SELF_URL?get_index=paysys_payment&SUM=%RECOMENDED_PAY%' class='btn btn-primary'>Пополнить счет !</a>
            </div>
            <div class="icon">
                <i class="ion ion-pie-graph"></i>
            </div>
            <a href="/index.cgi?index=10" class="small-box-footer">_{INFO}_ <i class="fa fa-arrow-circle-right"></i></a>
        </div>

        %BIG_BOX%
        <!-- /.box -->

    </section>
    <!-- /.Left col -->
    <!-- right col (We are only adding the ID to make the widgets sortable)-->
    <section class="col-lg-4 connectedSortable">
        <!-- /.box-header -->

        %SMALL_BOX%

        <div class="callout callout-info">
            <p>Вы хотите зарегистрировать мак адрес текущего устройства?</p>

            <label>
                <input type="checkbox"> Подтвердить
            </label>
            <button type="submit" class="btn btn-primary">ДА !</button>
        </div>

        <div class="callout callout-warning">
            <h4></h4>

            <p>Отменить приостановление?</p>
            <label>
                <input type="checkbox"> Подтвердить
            </label>
            <a href='$SELF_URL?get_index=dv_user_info&del=1' class='btn btn-primary'>ДА !</a>

        </div>

        <!-- /.box-body -->

    </section>
    <!-- right col -->
</div>

