var config = {
  props: ["config"],
  template: `
      <div>
        <h4>Facebook Plugin</h4>
          <div class='col-xs-9'>
            <input placeholder="Page name" v-model="page_name" class='form-control'/>
          </div>


      </div>
    `,

  data: () => ({
    advanced: false,
  }),
  computed: {
    page_name: ChildTile.config_value("page_name", ""),
  },
  methods: {
    onClick: function (evt) {
      // this.$emit('setConfig', 'foo', 'bar');
    },
  },
};

ChildTile.register({
  config: config,
});
