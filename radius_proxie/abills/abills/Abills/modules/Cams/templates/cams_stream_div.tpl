<div class='col-md-6'>
  <div class='box box-theme' data-stream='https://%SERVER_IP%:%SERVER_PORT%/hls/%STREAM_HASH_NAME%/%STREAM_HASH_NAME%.m3u8'>
    <div class="box-heading">%STREAM_NAME%</div>
    <div class="box-body">
      <div data-live='true' data-ratio='0.5625' class='flowplayer no-mute no-volume play-button is-splash'>

        <video data-title='%STREAM_NAME%'>
          <source type='application/x-mpegurl'
                  src='https://%SERVER_IP%:%SERVER_PORT%/hls/%STREAM_HASH_NAME%/%STREAM_HASH_NAME%.m3u8'>
        </video>
      </div>
    </div>
  </div>
</div>